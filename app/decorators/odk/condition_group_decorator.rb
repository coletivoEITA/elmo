module Odk
  class ConditionGroupDecorator < BaseDecorator

    def to_odk
      conjuction = (true_if == "all_met") ? I18n.t("common.and") : I18n.t("common.or")
      result = decorated_members.map{ |m| "(#{m.to_odk})"}.join(" #{conjuction} ")
      if negate?
        result = "not(#{result})"
      end
      decorated_members.count == 0 ? nil : result
    end

    private

    def decorated_members
      # Don't use draper decorate_collection so we can mock in tests
      members.map{|m| Odk::DecoratorFactory.decorate(m)}
    end

  end
end