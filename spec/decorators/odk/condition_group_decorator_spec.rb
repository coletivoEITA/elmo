require "spec_helper"

module Odk
  describe ConditionGroupDecorator, :odk, :reset_factory_sequences, database_cleaner: :truncate do
    context "non-nested condition group all true" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")]) }
      it "" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk


        expect(result).to eq "(a) and (b) and (c)"
      end
    end

    context "non-nested condition group negated" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"), double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"), double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")]) }

      it "" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "not((a) and (b) and (c))"
      end
    end

    context "non-nested condition group with any true" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "any_met", negate: false, members: [double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"), double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"), double(Odk::ConditionDecorator, decorated?: true, to_odk: "c")]) }

      it "" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq "(a) or (b) or (c)"
      end
    end

    context "nested condition group" do

      let(:condition_group) { Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [

        #decorated? replace w/ draper property that says it's already decorated
        instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "a"),
        Forms::ConditionGroup.new( true_if: "all_met", negate: true, members: [instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "b"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "c"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "d")]),
        Forms::ConditionGroup.new( true_if: "all_met", negate: false, members: [instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "e"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "f"), instance_double(Odk::ConditionDecorator, decorated?: true, to_odk: "g")])
      ]) }

      it "TODO" do
        result = Odk::DecoratorFactory.decorate(condition_group).to_odk
        expect(result).to eq ""
      end
    end

    def decorate(obj)
      Odk::DecoratorFactory.decorate(obj)
    end
  end
end