# frozen_string_literal: true

# Generates human readable representation of Skip Rules
class SkipRuleDecorator < ApplicationDecorator
  delegate_all

  def human_readable
    I18n.t("skip_rule.instructions",
      destination: display_destination,
      conditions: decorate_conditions)
  end

  def decorate_conditions
    decorated_conditions = ConditionDecorator.decorate_collection(condition_group.members)
    concatenator = condition_group.true_if == "all_met" ? I18n.t("common.AND") : I18n.t("common.OR")
    decorated_conditions.map(&:human_readable).join(" #{concatenator} ")
  end

  def display_destination
    if destination == "item"
      "#{I18n.t("activerecord.models.question.one")} #{QuestioningDecorator.new(dest_item).name_and_rank}"
    else
      I18n.t("skip_rule.end_of_form")
    end
  end

  def read_only_header
    "#{I18n.t("skip_rule.skip_to_item", label: display_destination)} #{I18n.t("skip_rule.skip_if_options.#{skip_if}")}"
  end
end
