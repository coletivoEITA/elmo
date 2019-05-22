# frozen_string_literal: true

require "rails_helper"

describe Odk::ConditionDecorator do
  include_context "odk rendering"

  describe "to_odk", :odk do
    let(:qing1) { decorate(form.c[0]) }
    let(:opt_set) { form.c[0].option_set }
    let(:option_node) { form.c[0].option_set.c[0] }
    let(:hostq) { decorate(form.c.last) }
    let(:condition) { Condition.new({conditionable: hostq.object}.merge(params)) }
    subject(:xpath) { decorate(condition).to_odk }

    context "for single level select one question" do
      let(:form) { create(:form, question_types: %w[select_one text]) }

      context "with eq operator" do
        let(:params) { {left_qing: qing1.object, op: "eq", option_node: option_node} }

        it do
          expect(xpath).to eq("selected(/data/#{qing1.odk_code}, 'on#{option_node.id}')")
        end
      end

      context "with neq operator" do
        let(:params) { {left_qing: qing1.object, op: "neq", option_node: option_node} }

        it do
          expect(xpath).to eq("not(selected(/data/#{qing1.odk_code}, 'on#{option_node.id}'))")
        end
      end
    end

    context "for multilevel select one question" do
      let(:form) { create(:form, question_types: %w[multilevel_select_one]) }
      let(:subqing1) { decorate(qing1.subqings[0]) }
      let(:subqing2) { decorate(qing1.subqings[1]) }

      context "for first level" do
        let(:params) { {left_qing: qing1.object, op: "eq", option_node: opt_set.c[0]} }

        it do
          expect(xpath).to eq("selected(/data/#{subqing1.odk_code}, 'on#{opt_set.c[0].id}')")
        end
      end

      context "for second level" do
        let(:params) { {left_qing: qing1.object, op: "eq", option_node: opt_set.c[0].c[1]} }

        it do
          expect(xpath).to eq("selected(/data/#{subqing2.odk_code}, 'on#{opt_set.c[0].c[1].id}')")
        end
      end
    end

    context "for select multiple question" do
      let(:form) { create(:form, question_types: %w[select_multiple text]) }

      context "with inc operator" do
        let(:params) { {left_qing: qing1.object, op: "inc", option_node: option_node} }

        it do
          expect(xpath).to eq("selected(/data/#{qing1.odk_code}, 'on#{option_node.id}')")
        end
      end

      context "with ninc operator" do
        let(:params) { {left_qing: qing1.object, op: "ninc", option_node: option_node} }

        it do
          expect(xpath).to eq("not(selected(/data/#{qing1.odk_code}, 'on#{option_node.id}'))")
        end
      end
    end

    context "for non-select question" do
      let(:form) { create(:form, question_types: %w[integer text date time datetime text]) }
      let(:int_q) { decorate(form.c[0]) }
      let(:text_q) { decorate(form.c[1]) }
      let(:date_q) { decorate(form.c[2]) }
      let(:time_q) { decorate(form.c[3]) }
      let(:datetime_q) { decorate(form.c[4]) }

      context "with eq operator and int question" do
        let(:params) { {left_qing: int_q.object, op: "eq", value: "5"} }

        it do
          expect(xpath).to eq("/data/#{int_q.odk_code} = 5")
        end
      end

      context "with neq operator and text question" do
        let(:params) { {left_qing: text_q.object, op: "neq", value: "foo"} }

        it do
          expect(xpath).to eq("/data/#{text_q.odk_code} != 'foo'")
        end
      end

      context "with date question and geq operator" do
        let(:params) { {left_qing: date_q.object, op: "geq", value: "1981-10-26"} }

        it do
          expect(xpath).to eq("format-date(/data/#{date_q.odk_code}, '%Y%m%d') >= '19811026'")
        end
      end

      context "with time question and leq operator" do
        let(:params) { {left_qing: time_q.object, op: "leq", value: "3:56pm"} }

        it do
          expect(xpath).to eq("format-date(/data/#{time_q.odk_code}, '%H%M') <= '1556'")
        end
      end

      context "with datetime question and gt operator" do
        let(:params) { {left_qing: datetime_q.object, op: "gt", value: "Dec 3 2003 11:56"} }

        it do
          expect(xpath).to eq("format-date(/data/#{datetime_q.odk_code}, '%Y%m%d%H%M') > '200312031156'")
        end
      end
    end

    context "for intra-group reference" do
      let(:form) { create(:form, question_types: [%w[multilevel_select_one text text]]) }
      let(:q1) { decorate(form.sorted_children[0].sorted_children[0]) }
      let(:q2) { decorate(form.sorted_children[0].sorted_children[1]) }

      context "for regular ref qing" do
        let(:params) { {left_qing: q2.object, op: "eq", value: "foo"} }

        it do
          expect(xpath).to eq("../#{q2.odk_code} = 'foo'")
        end
      end

      context "for multilevel ref qing" do
        let(:option_node) { q1.option_set.sorted_children[0].sorted_children[0] }
        let(:params) { {left_qing: q1.object, op: "eq", option_node: option_node} }

        it do
          expect(xpath).to eq("selected(../#{q1.odk_code}_2, '#{option_node.odk_code}')")
        end
      end
    end

    context "for right_side_type qing" do
      let(:form) { create(:form, question_types: %w[text text]) }
      let(:params) { {left_qing: hostq.object, op: "eq", right_side_type: "qing", right_qing: qing1.object} }

      it "temporarily ignores" do
        expect(xpath).to eq("true()")
      end
    end
  end
end
