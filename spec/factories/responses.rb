# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: responses
#
#  id                :uuid             not null, primary key
#  checked_out_at    :datetime
#  incomplete        :boolean          default(FALSE), not null
#  odk_hash          :string(255)
#  odk_xml           :text
#  reviewed          :boolean          default(FALSE), not null
#  reviewer_notes    :text
#  shortcode         :string(255)      not null
#  source            :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  checked_out_by_id :uuid
#  form_id           :uuid             not null
#  mission_id        :uuid             not null
#  old_id            :integer
#  reviewer_id       :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_responses_on_checked_out_at        (checked_out_at)
#  index_responses_on_checked_out_by_id     (checked_out_by_id)
#  index_responses_on_created_at            (created_at)
#  index_responses_on_form_id               (form_id)
#  index_responses_on_form_id_and_odk_hash  (form_id,odk_hash) UNIQUE
#  index_responses_on_mission_id            (mission_id)
#  index_responses_on_reviewed              (reviewed)
#  index_responses_on_reviewer_id           (reviewer_id)
#  index_responses_on_shortcode             (shortcode) UNIQUE
#  index_responses_on_updated_at            (updated_at)
#  index_responses_on_user_id               (user_id)
#  index_responses_on_user_id_and_form_id   (user_id,form_id)
#
# Foreign Keys
#
#  responses_checked_out_by_id_fkey  (checked_out_by_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_form_id_fkey            (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_mission_id_fkey         (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_reviewer_id_fkey        (reviewer_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_user_id_fkey            (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# ResponseFactoryHelper builds a response tree based on answer_values
# About the answer_values format:
# The value of a select multiple or multilevel select answer is an array.
#   For example, %w[Dog Cat] or %w[Cat] or %w[Plant Oak] or %w[Plant]
# All other answer types are represented by an integer, string, or object as appropriate
# A non repeat answer group of answers is an array of answer values
# A repeat group is a hash with the key :repeating whose value is an array of answer group arrays
#   e.g. {repeating: [ [1, "A"], [2, "B"] ] } where the group has an integer question and a text question
#
# Example answer_values with nested repeat groups:
# root AnswerGroup    [
# AnswerGroup          [
# Answer                1
#                      ],
# Answer               create(:media_image),
# Answer               %w[Plant Oak],
# Outer rpt grp set   {repeating: [
# Outer grp instance1   [
# Answer                 2,
# Inner rpt grp set       {repeating: [
# Inner rpt grp instance1   [
# Answer                      "a",
# Answer                      10
#                           ],
# Inner rpt grp instance2   [
# Answer                      "b",
# Answer                      11
#                           ]
#                        ]}
#                       ]
#                     ]}
#                    ]
#
# If an answer value is nil, no answer node is created. If the answer value is "" an answer node is
# created with no value. Nil implies that an answer is irrelevant (the factory treats answers with nil value
# the way parsers treat irrelevant answers.) Use "" as the value for answers that are relevant but blank.

module ResponseFactoryHelper
  # Returns a potentially nested array of answers.
  def self.build_answers(response, answer_values)
    root = response.build_root_node({type: "AnswerGroup", form_item: response.form.root_group}
      .merge(rank_attributes(nil)))
    add_level(response.form.sorted_children, answer_values, root)
    root
  end

  def self.add_level(form_items, answer_values, parent)
    unless answer_values.nil?
      form_items.each_with_index do |item, i|
        answer_data = answer_values[i]
        next if answer_data.nil?
        case item
        when Questioning
          add_answer(item, answer_data, parent)
        when QingGroup
          # :repeating key is only present when answer group set has not been built yet
          if item.repeatable? && answer_data.is_a?(Hash) && answer_data.key?(:repeating)
            add_group_set(item, answer_data, parent)
          else
            # group is not repeating, or parent is answer group set for repeat group.
            add_group(item, answer_data, parent)
          end
        end
      end
    end
    parent
  end

  # form_group must be repeating
  # value_data is in shape of: {repeating: [[1, "A", "Hi"], [2, "B", "Bye"]]}
  # parent must be an AnswerGroup
  def self.add_group_set(form_group, value_data, parent)
    group_instances = value_data[:repeating]
    group_set = parent.children.build({
      type: "AnswerGroupSet",
      form_item: form_group
    }.merge(rank_attributes(parent)))
    group_instances.each do |group_instance_answer_values| # each array represents one group
      add_group(form_group, group_instance_answer_values, group_set)
    end
  end

  # form_group may or may not be repeating
  # answer_values is an array of answers or groups in this group
  # parent must be an AnswerGroup (if form item not repeating) or AnswerGroupSet (if form item is repeating)
  def self.add_group(form_group, answer_values, parent)
    answer_group = parent.children.build({type: "AnswerGroup", form_item: form_group}
      .merge(rank_attributes(parent)))
    add_level(form_group.c, answer_values, answer_group)
  end

  # value may be integer, string, object, or (for select one or multilevel only) an array of strings
  # parent must be an AnswerGroup or AnswerSet
  def self.add_answer(questioning, value, parent)
    if questioning.multilevel? # only answers to multilevel questions need AnswerSets.
      build_answer_set(questioning, value, parent)
    else
      parent.children.build(build_answer_attrs(questioning, value, parent))
    end
  end

  # values is an array of strings, which should match an option or be ''
  # parent must be an AnswerGroup
  def self.build_answer_set(qing, values, parent)
    set = parent.children.build({type: "AnswerSet", form_item: qing}
      .merge(rank_attributes(parent)))
    if values.present?
      values.each do |v|
        next if v.blank?
        option = qing.all_options.select { |o| o.canonical_name == v }.first
        option_id = option.present? ? option.id : nil
        set.children.build(
          {
            type: "Answer",
            form_item: qing,
            option_id: option_id
          }.merge(rank_attributes(set))
        )
      end
    end
    set
  end

  def self.build_answer_attrs(qing, value, parent)
    attrs = {
      type: "Answer",
      form_item: qing
    }
    attrs.merge!(rank_attributes(parent))
    case qing.qtype_name
    when "select_one" # not multilevel
      if value.present?
        option = qing.all_options.select { |o| o.canonical_name == value }.first
        attrs[:option_id] = option.id
      end
    when "select_multiple"
      options_by_name = qing.options.index_by(&:name)
      choices = value.map do |c|
        Choice.new(option: options_by_name[c]) || raise("could not find option with name '#{c}'")
      end
      attrs[:choices] = choices
    when "date", "time", "datetime"
      attrs["#{qing.qtype_name}_value"] = value
    when "image", "annotated_image", "signature", "sketch", "audio", "video"
      attrs[:media_object] = value
    else
      attrs[:value] = value
    end
    attrs
  end

  def self.rank_attributes(tree_parent)
    {new_rank: tree_parent.present? ? tree_parent.children.length : 0}
  end
end

FactoryGirl.define do
  factory :response do
    transient do
      answer_values []
    end

    user
    mission { get_mission }
    form { create(:form, :published, mission: mission) }
    source "web"

    trait :is_reviewed do
      transient do
        reviewer_name "Default"
      end
      reviewed true
      reviewer_notes { Faker::Lorem.paragraphs }
      reviewer { create(:user, name: reviewer_name) }
    end

    # Ensure unpublished form associations have been published at least once
    after(:build) do |response, evaluator|
      form = response.form
      unless form.published? && form.current_version.present?
        form.publish!
        form.unpublish!
      end
      # Build answer objects from answer_values array
      ResponseFactoryHelper.build_answers(response, evaluator.answer_values) if evaluator.answer_values
    end
  end
end
