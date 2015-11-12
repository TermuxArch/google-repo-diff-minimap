module.exports =
  # Sets the @gRepo instance
  setInstance: (@gRepo) ->
  
  # Returns the repository for the given path
  repositoryForPath: (path) -> @gRepo?.host?.getRepoForPath?(path)