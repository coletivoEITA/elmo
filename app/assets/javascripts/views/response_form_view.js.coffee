class ELMO.Views.ResponseFormView extends ELMO.Views.ApplicationView

  initialize: (params) ->
    # Select2's for user and reviewer
    @$('#response_user_id').select2
      ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(params.submitter_url, 'possible_users', 'name')
    @$('#response_reviewer_id').select2
      ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(params.reviewer_url, 'possible_users', 'name')

    @locationPicker = new ELMO.LocationPicker(@$('#location-picker-modal'))

  events:
    'click .qtype-location .widget a': 'showLocationPicker'

  showLocationPicker: (e) ->
    e.preventDefault()
    field = @$(e.target).closest('.widget').find('input[type=text]')
    @locationPicker.show(field)
