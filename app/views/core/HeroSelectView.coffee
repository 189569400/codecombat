require('app/styles/core/hero-select-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/core/hero-select-view'
State = require 'models/State'
ThangTypeConstants = require 'lib/ThangTypeConstants'
ThangTypeLib = require 'lib/ThangTypeLib'
User = require 'models/User'
api = require 'core/api'
utils = require 'core/utils'

module.exports = class HeroSelectView extends CocoView
  id: 'hero-select-view'
  template: template

  events:
    'click .hero-option': 'onClickHeroOption'

  initialize: (@options = {}) ->
    if utils.isCodeCombat
      defaultHeroOriginal = ThangTypeConstants.heroes.captain
      currentHeroOriginal = me.get('heroConfig')?.thangType or defaultHeroOriginal
    else
      defaultHeroOriginal = ThangTypeConstants.ozariaHeroes['hero-b']
      currentHeroOriginal = me.get('ozariaUserOptions')?.isometricThangTypeOriginal or defaultHeroOriginal

    @debouncedRender = _.debounce @render, 0

    @state = new State({
      currentHeroOriginal
      selectedHeroOriginal: currentHeroOriginal
    })

    if utils.isCodeCombat
      api.thangTypes.getHeroes({ project: ['original', 'name', 'shortName', 'i18n', 'heroClass', 'slug', 'ozaria', 'poseImage'] }).then (heroes) =>
        return if @destroyed
        @heroes = heroes.filter (hero) ->
          return false if hero.ozaria
          if clanHero = _.find(utils.clanHeroes, thangTypeOriginal: hero.original)
            return false if clanHero.clanId not in (me.get('clans') ? [])
          if hero.original is ThangTypeConstants.heroes['code-ninja']
            return false if window.location.host isnt 'coco.code.ninja'
          true
        @debouncedRender()
     else
      # @heroes = new ThangTypes({}, { project: ['original', 'name', 'heroClass, 'slug''] })
      # @supermodel.trackRequest @heroes.fetchHeroes()

      api.thangTypes.getHeroes({ project: ['original', 'name', 'shortName', 'heroClass', 'slug', 'ozaria'] }).then (heroes) =>
        @heroes = heroes.filter((h) => !h.ozaria)
        @debouncedRender()

    @listenTo @state, 'all', -> @debouncedRender()
    # @listenTo @heroes, 'all', -> @debouncedRender()

  onClickHeroOption: (e) ->
    heroOriginal = $(e.currentTarget).data('hero-original')
    @state.set selectedHeroOriginal: heroOriginal
    @saveHeroSelection(heroOriginal)

  getPortraitURL: (hero) ->
    ThangTypeLib.getPortraitURL(hero)

  getHeroShortName: (hero) ->
    ThangTypeLib.getHeroShortName(hero)

  saveHeroSelection: (heroOriginal) ->
    me.set(heroConfig: {}) unless me.get('heroConfig')
    heroConfig = _.assign {}, me.get('heroConfig'), { thangType: heroOriginal }
    me.set({ heroConfig })

    hero = _.find(@heroes, { original: heroOriginal })
    me.save().then =>
      return if utils.isCodeCmbat and @destroyed
      event = 'Hero selected'
      event += if me.isStudent() then ' student' else ' teacher'
      event += ' create account' if @options.createAccount
      category = if me.isStudent() then 'Students' else 'Teachers'
      window.tracker?.trackEvent event, {category, heroOriginal}
      @trigger 'hero-select:success', {attributes: hero}
