# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: report_reports
#
#  id               :uuid             not null, primary key
#  aggregation_name :string(255)
#  bar_style        :string(255)      default("side_by_side")
#  display_type     :string(255)      default("table")
#  filter           :text
#  group_by_tag     :boolean          default(FALSE), not null
#  name             :string(255)      not null
#  percent_type     :string(255)      default("none")
#  question_labels  :string(255)      default("title")
#  question_order   :string(255)      default("number"), not null
#  text_responses   :string(255)      default("all")
#  type             :string(255)      not null
#  unique_rows      :boolean          default(FALSE)
#  unreviewed       :boolean          default(FALSE)
#  view_count       :integer          default(0), not null
#  viewed_at        :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  creator_id       :uuid
#  disagg_qing_id   :uuid
#  form_id          :uuid
#  mission_id       :uuid             not null
#
# Indexes
#
#  index_report_reports_on_creator_id      (creator_id)
#  index_report_reports_on_disagg_qing_id  (disagg_qing_id)
#  index_report_reports_on_form_id         (form_id)
#  index_report_reports_on_mission_id      (mission_id)
#  index_report_reports_on_view_count      (view_count)
#
# Foreign Keys
#
#  report_reports_creator_id_fkey      (creator_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_disagg_qing_id_fkey  (disagg_qing_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_form_id_fkey         (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  report_reports_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

# There are more report tests in test/unit/report.
require 'rails_helper'

describe Report::ResponseTallyReport do
  include_context "reports"

  context 'with multilevel option set' do
    before do
      @form = create(:form, question_types: %w(multilevel_select_one))
      create(:response, form: @form, answer_values: [['Animal', 'Cat']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal', 'Dog']], source: 'web')
      create(:response, form: @form, answer_values: [['Animal']], source: 'odk')
      create(:response, form: @form, answer_values: [['Plant', 'Oak']], source: 'odk')
      @report = create(:response_tally_report, _calculations: [@form.questions[0], 'source'], run: true)
    end

    it 'should count only top-level answers' do
      expect(@report).to have_data_grid(
        %w(       odk web TTL),
        %w(Animal   1   2   3),
        %w(Plant    1   _   1),
        %w(TTL      2   2   4)
      )
    end
  end

  describe "results" do
    it "counts of yes, no per day for a given question" do
      # create several yes/no questions and responses for them
      yes_no = create(:option_set, option_names: %w(Yes No))
      questions = [create(:question, code: "yn", qtype_name: "select_one", option_set: yes_no)]
      form = create(:form, questions: questions)
      create_list(:response, 1, form: form, created_at: "2012-01-01 1:00:00", answer_values: %w(Yes))
      create_list(:response, 2, form: form, created_at: "2012-01-05 1:00:00", answer_values: %w(Yes))
      create_list(:response, 6, form: form, created_at: "2012-01-05 1:00:00", answer_values: %w(No))

      # Ensure destroyed data is ignored
      decoy = create(:response, form: form, created_at: "2012-01-01 1:00:00", answer_values: %w(Yes))
      decoy.destroy

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, attrib1_name: :date_submitted),
        Report::IdentityCalculation.new(rank: 2, question1: questions[0])
      ])

      expect(report).to have_data_grid(%w(             Yes No TTL ),
                                       %w( 2012-01-01    1  _   1 ),
                                       %w( 2012-01-05    2  6   8 ),
                                       %w( TTL           3  6   9 ))
    end

    it "total number of responses per form per source" do
      forms = [0, 1].map{ |i| create(:form, name: "f#{i}") }
      create_list(:response, 2, form: forms[0], source: "odk")
      create_list(:response, 5, form: forms[0], source: "web")
      create_list(:response, 8, form: forms[1], source: "odk")
      create_list(:response, 3, form: forms[1], source: "web")

      report = create_report("ResponseTally", calculations: [Report::IdentityCalculation.new(rank: 1, attrib1_name: :form)])
      expect(report).to have_data_grid(%w(   Tally TTL ),
                                       %w(  f0  7   7 ),
                                       %w(  f1 11  11 ),
                                       %w( TTL 18  18 ))

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, attrib1_name: :form),
        Report::IdentityCalculation.new(rank: 2, attrib1_name: :source)
      ])

      expect(report).to have_data_grid(%w(     odk web TTL ),
                                       %w(  f0   2   5   7 ),
                                       %w(  f1   8   3  11 ),
                                       %w( TTL  10   8  18 ))
    end

    it "total number of responses per source per answer" do
      yes_no = create(:option_set, option_names: %w(Yes No))
      questions = [create(:question, code: "yn", qtype_name: "select_one", option_set: yes_no)]
      form = create(:form, questions: questions)
      create_list(:response, 2, form: form, source: "odk", answer_values: %w(Yes))
      create_list(:response, 5, form: form, source: "web", answer_values: %w(Yes))
      create_list(:response, 8, form: form, source: "odk", answer_values: %w(No))
      create_list(:response, 3, form: form, source: "web", answer_values: %w(No))

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, attrib1_name: :source),
        Report::IdentityCalculation.new(rank: 2, question1: questions[0])
      ])
      expect(report).to have_data_grid(%w(     Yes  No TTL ),
                                       %w( odk   2   8  10 ),
                                       %w( web   5   3   8 ),
                                       %w( TTL   7  11  18 ))
    end

    it "total number of responses per source per zero-nonzero answer" do
      questions = [create(:question, qtype_name: "integer")]
      form = create(:form, questions: questions)
      create_list(:response, 2, form: form, source: "odk", answer_values: %w(4))
      create_list(:response, 5, form: form, source: "web", answer_values: %w(9))
      create_list(:response, 8, form: form, source: "odk", answer_values: %w(0))
      create_list(:response, 3, form: form, source: "web", answer_values: %w(0))

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, attrib1_name: :source),
        Report::ZeroNonzeroCalculation.new(rank: 2, question1: questions[0])
      ])

      expect(report).to have_data_grid(%w(     Zero  One_or_More TTL ),
                                      %w( odk     8            2  10 ),
                                      %w( web     3            5   8 ),
                                      %w( TTL    11            7  18 ))
    end

    it "total number of responses per two different answers" do
      yes_no = create(:option_set, option_names: %w(Yes No))
      high_low = create(:option_set, option_names: %w(High Low))
      questions = []
      questions << create(:question, qtype_name: "select_one", option_set: yes_no)
      questions << create(:question, qtype_name: "select_one", option_set: high_low)
      forms = create_list(:form, 2, questions: questions)
      create_list(:response, 2, form: forms[0], answer_values: %w(Yes High))
      create_list(:response, 5, form: forms[0], answer_values: %w(No High))
      create_list(:response, 8, form: forms[0], answer_values: %w(Yes Low))
      create_list(:response, 3, form: forms[0], answer_values: %w(No Low))
      create_list(:response, 2, form: forms[1], answer_values: %w(Yes High))

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, question1: questions[0]),
        Report::IdentityCalculation.new(rank: 2, question1: questions[1])
      ])
      expect(report).to have_data_grid(%w(    High Low TTL ),
                                       %w( Yes   4   8  12 ),
                                       %w( No    5   3   8 ),
                                       %w( TTL   9  11  20 ))

      report = create_report("ResponseTally", calculations: [
        Report::IdentityCalculation.new(rank: 1, question1: questions[0]),
        Report::IdentityCalculation.new(rank: 2, question1: questions[1])
      ], filter: %Q{form: "#{forms[0].name}"})

      expect(report).to have_data_grid(%w(    High Low TTL ),
                                       %w( Yes   2   8  10 ),
                                       %w( No    5   3   8 ),
                                       %w( TTL   7  11  18 ))

    end
  end
end
