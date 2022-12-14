require('app/styles/editor/level/thang/level-thang-edit-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/editor/level/thang/level-thang-edit-view'
ThangComponentsEditView = require 'views/editor/component/ThangComponentsEditView'
ThangType = require 'models/ThangType'
ace = require('lib/aceContainer')
utils = require 'core/utils'
require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')

module.exports = class LevelThangEditView extends CocoView
  ###
  In the level editor, is the bar at the top when editing a single thang.
  Everything below is part of the ThangComponentsEditView, which is shared with the
  ThangType editor view.
  ###

  id: 'level-thang-edit-view'
  template: template

  events:
    'click #all-thangs-link': 'navigateToAllThangs'
    'click #thang-name-link span': 'toggleNameEdit'
    'click #thang-type-link span': 'toggleTypeEdit'
    'blur #thang-name-link input': 'toggleNameEdit'
    'blur #thang-type-link input': 'toggleTypeEdit'
    'keydown #thang-name-link input': 'toggleNameEditIfReturn'
    'keydown #thang-type-link input': 'toggleTypeEditIfReturn'
    'click #prev-thang-link': 'navigateToPreviousThang'
    'click #next-thang-link': 'navigateToNextThang'

  subscriptions:
    'editor:level-thangs-changed': 'onThangsEdited'

  constructor: (options) ->
    options ?= {}
    super options
    @world = options.world
    @thangData = $.extend true, {}, options.thangData ? {}
    @level = options.level
    @oldPath = options.oldPath
    @reportChanges = _.debounce @reportChanges, 500

  onLoaded: -> @render()
  afterRender: ->
    super()
    thangType = @supermodel.getModelByOriginal(ThangType, @thangData.thangType)
    options =
      components: @thangData.components
      supermodel: @supermodel
      level: @level
      world: @world

    if @level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev') or utils.isCodeCombat then options.thangType = thangType

    @thangComponentEditView = new ThangComponentsEditView options
    @listenTo @thangComponentEditView, 'components-changed', @onComponentsChanged
    @insertSubView @thangComponentEditView
    thangTypeNames = (m.get('name') for m in @supermodel.getModels ThangType)
    input = @$el.find('#thang-type-link input').autocomplete(source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true)
    thangType = _.find @supermodel.getModels(ThangType), (m) => m.get('original') is @thangData.thangType
    thangTypeName = thangType?.get('name') or 'None'
    input.val(thangTypeName)
    @$el.find('#thang-type-link span').text(thangTypeName)
    @hideLoading()

  navigateToAllThangs: ->
    Backbone.Mediator.publish 'editor:level-thang-done-editing', {thangData: $.extend(true, {}, @thangData), oldPath: @oldPath}

  navigateToPreviousThang: (e) ->
    @navigateThangsInDirection -1

  navigateToNextThang: (e) ->
    @navigateThangsInDirection 1

  navigateThangsInDirection: (dir) ->
    flattenedThangs = @parent.flattenThangs @parent.groupThangs @level.get('thangs')
    currentIndex = _.findIndex flattenedThangs, id: @thangData.id
    if nextThang = flattenedThangs[(currentIndex + dir + flattenedThangs.length) % flattenedThangs.length]
      Backbone.Mediator.publish 'editor:edit-level-thang', {thangID: nextThang.id}

  toggleNameEdit: ->
    link = @$el.find '#thang-name-link'
    wasEditing = link.find('input:visible').length
    span = link.find('span')
    input = link.find('input')
    if wasEditing then span.text(input.val()) else input.val(span.text())
    link.find('span, input').toggle()
    input.select() unless wasEditing
    @thangData.id = span.text()

  toggleTypeEdit: ->
    link = @$el.find '#thang-type-link'
    wasEditing = link.find('input:visible').length
    span = link.find('span')
    input = link.find('input')
    span.text(input.val()) if wasEditing
    link.find('span, input').toggle()
    input.select() unless wasEditing
    thangTypeName = input.val()
    thangType = _.find @supermodel.getModels(ThangType), (m) -> m.get('name') is thangTypeName
    if thangType and wasEditing
      @thangData.thangType = thangType.get('original')

  toggleNameEditIfReturn: (e) ->
    @$el.find('#thang-name-link input').blur() if e.which is 13

  toggleTypeEditIfReturn: (e) ->
    @$el.find('#thang-type-link input').blur() if e.which is 13

  onComponentsChanged: (components) =>
    @thangData.components = components
    @reportChanges()

  reportChanges: =>
    return if @destroyed
    @reporting = true
    Backbone.Mediator.publish 'editor:level-thang-edited', {thangData: $.extend(true, {}, @thangData), oldPath: @oldPath}
    @reporting = false

  onThangsEdited: (e) ->
    # Propagate these edits to our Thang
    return if @reporting  # Not if they're our own edits
    return unless newThang = _.find e.thangs, id: @thangData.id
    return if _.isEqual newThang, @thangData
    @thangData = newThang
    @thangComponentEditView.components = newThang.components ? []
    @thangComponentEditView.onComponentsChanged()
