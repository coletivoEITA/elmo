# frozen_string_literal: true

module Searchers
  # Serializes a ResponsesSearcher for search filters.
  class ResponsesSearcherSerializer < SearcherSerializer
    attributes :all_forms, :selected_form_ids, :selected_qings, :is_reviewed,
      :selected_users, :selected_groups

    def selected_form_ids
      object.form_ids || []
    end

    def selected_qings
      object.qings || []
    end

    def is_reviewed
      object.is_reviewed
    end

    def selected_users
      object.submitters || []
    end

    def selected_groups
      object.groups || []
    end

    def advanced_search_text
      (Settings.filters_beta.present? ? object.advanced_text : object.query) || ""
    end
  end
end
