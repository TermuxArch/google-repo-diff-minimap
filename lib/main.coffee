{CompositeDisposable, Disposable} = require 'atom'
helper                            = require './helpers'

MinimapGoogleDiffBinding = null

class Main
  
  # Whether or not the minimap portion of the plugin is active
  minimap_active: false
  # Whether or not the google-repo portion of the plugin is active
  gRepo_active: false
  
  
  # Whether or not the minimap portion of the plugin is active
  isActive: -> @minimap_active
  # Whether or not the google-repo portion of the plugin is active
  gRepo_isActive: -> @gRepo_active
  
  
  # Activates the package
  activate: ->
    @bindings = new WeakMap
  
  
  # deactivates the package
  deactivate: ->
    @destroyBindings()
    @minimap?.unregisterPlugin 'google-repo-diff'          # Unregsiter this plugin from minimap
    @gRepo?.unregisterPlugin   'google-repo-diff-minimap'  # Unregister this plugin from google-repo
    @minimap = null
  
  
  # Consumes the google-repo object
  consumeGoogleRepoServiceV1: (@gRepo) ->
    helper.setInstance @gRepo                               # Put the instance into the helpers - needed to get the proper repository
    @gRepo.registerPlugin "google-repo-diff-minimap", this  # Register this plugin with google-repo
  
  # Comsumes the minimap object
  consumeMinimapServiceV1: (@minimap) ->
    @minimap.registerPlugin 'google-repo-diff', this  # Regsiter this plugin with minimap
  
  
  # Activates the minimap portion of the plugin
  activatePlugin: ->
    return if @minimap_active
    
    @subscriptions = new CompositeDisposable
    
    try
      @activateBinding()
      @minimap_active = true
      
      @subscriptions.add @minimap.onDidActivate @activateBinding
      @subscriptions.add @minimap.onDidDeactivate @destroyBindings
    catch e
      console.log e
  
  
  # Deactivates the minimap portion of the plugin
  deactivatePlugin: ->
    return unless @minimap_active
    
    @minimap_active = false
    @subscriptions.dispose()
    @destroyBindings()
  
  
  # Called when the 'google-repo' package activates this plugin
  gRepo_activatePlugin: ->
    return if @gRepo_active  # If the plugin is already activated, there's no point in continuing
    
    @gRepo_active = true                                                   # State that this plugin is now active
    @gRepo_subscriptions = new CompositeDisposable                         # Create the subscriptions collection
    @gRepo_subscriptions.add @gRepo.onRepoListChange => @createBindings()  # Re-build the observers when the repository list changes
    @createBindings()                                                      # Observe the editor now
  
  
  # Called when the 'google-repo' package deactivates this plugin
  gRepo_deactivatePlugin: ->
    return unless @gRepo_active  # If the plugin is already deactivated, there's no point in continuing
    
    @gRepo_active = false           # State that this plugin is no longer active
    @gRepo_subscriptions.dispose()  # Dispose of the subscriptions
    @gRepo_subscriptions = null     # Remove the subscriptions object
  
  
  # Does something
  activateBinding: =>
    @createBindings() if Object.keys(helper.gRepo.host._repos).length > 0
    
    @subscriptions.add atom.project.onDidChangePaths =>
      
      if Object.keys(helper.gRepo.host._repos).length > 0
        @createBindings()
      else
        @destroyBindings()
  
  
  # Does another thing
  createBindings: =>
    return unless Object.keys(helper.gRepo.host._repos).length > 0
    
    MinimapGoogleDiffBinding ||= require './minimap-google-diff-binding'
    
    @subscriptions.add @minimap.observeMinimaps (o) =>
      minimap = o.view ? o
      editor = minimap.getTextEditor()
      
      return unless editor?
      
      binding = new MinimapGoogleDiffBinding minimap
      @bindings.set(minimap, binding)
  
  
  # Wheee! Look at how much I know!
  destroyBindings: =>
    return unless @minimap? and @minimap.editorsMinimaps?
    @minimap.editorsMinimaps.forEach (minimap) =>
      @bindings.get(minimap)?.destroy()
      @bindings.delete(minimap)

module.exports = new Main
