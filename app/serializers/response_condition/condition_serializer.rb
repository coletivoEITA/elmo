# frozen_string_literal: true

module ResponseCondition
  # Serializes condition for response web form display logic
  class ConditionSerializer < ActiveModel::Serializer
    attributes :left_qing_id, :op, :value, :option_node_id, :right_side_is_qing, :right_qing_id
    format_keys :lower_camel

    def right_side_is_qing
      object.right_side_is_qing?
    end
  end
end
