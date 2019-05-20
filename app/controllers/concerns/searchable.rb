# Methods pertaining to searching for objects in a controller action.
module Searchable
  extend ActiveSupport::Concern

  # If params[:search] is present, runs a search of `klass`,
  # passing `rel` as the relation to which to apply the search.
  # Returns the new relation if search succeeds,
  # otherwise sets flash, flash[:search_error] = true, and returns `rel` unchanged.
  def apply_search_if_given(klass, rel, **options)
    params[:search].present? ? apply_search(klass, rel, **options) : rel
  end

  def apply_search(klass, rel, **options)
    klass.do_search(rel, params[:search], {mission: current_mission}, options)
  rescue Search::ParseError => error
    flash.now[:error] = error.to_s
    flash.now[:search_error] = true
    rel
  end

  def init_filter_data
    @all_forms = Form.all.map { |item| {name: item.name, id: item.id} }.natural_sort_by_key
  end
end
