require("./style.scss")
LeaderboardForm = require '../../components/leaderboard_form/component'
MovieList = require '../../components/movie_list/component'
ActorList = require '../../components/actor_list/component'
Question = require '../../components/question/component'
Answer = require "../../components/answer/component"
AutoCompleteList = require '../../components/autocomplete/component'
Api = require "../../services/api"
Loader = require "../../components/loader/component"

moment = require 'moment'
_ = require 'underscore'


Card = require 'material-ui/lib/card/card'
CardHeader = require 'material-ui/lib/card/card-header'
Avatar = require 'material-ui/lib/avatar'
CardActions = require 'material-ui/lib/card/card-actions'
FlatButton = require 'material-ui/lib/flat-button'

Colors = require 'material-ui/lib/styles/colors'


injectTapEventPlugin = require "react-tap-event-plugin"
injectTapEventPlugin()

module.exports = React.createClass
  displayName: 'TheMovieGame'

  giveUp: ->
    if @state.score > 5
      @setState(showSaveModal: true)
    else
      @restart()

  restart: ->
    @setState(isLoading: true)
    prom = if @state.totalMoviePages > 1 then Api.getRandomMovie(Math.floor(Math.random()*@state.totalMoviePages)) else Api.getRandomMovie(@state.totalMoviePages)
    prom.always =>
      console.log "done"
      @setState( isLoading: false )
    prom.fail (err) ->
      console.log "handle error" + err
    prom.then (res) =>
      totalPages = if res.total_pages > 1000 then Math.floor(Math.random()*1000) else res.total_pages
      movie = res.results[Math.floor(Math.random()*res.results.length)]
      if @isNotReleased(movie.release_date)
        console.log "Movie " + movie.title + " isn't up to snuff because it hasn't come out yet"
        @restart()
      if @isTooObscure(movie.popularity)
        console.log "Movie " + movie.title + " isn't up to snuff because of popularity"
        @restart()
      else if @isNotAllowed(movie.genre_ids)
        console.log "Movie " + movie.title + " isn't up to snuff because its category isn't allowed"
        @restart()
      else if movie.original_language isnt "en"
        console.log "Movie " + movie.title + " isn't up to snuff because it's language isn't english"
        @restart()
      else if movie is @state.movie
        console.log "Movie " + movie.title + " isn't up to snuff because it was just used"
        @restart()
      else
        if @state.score > 0
          @replaceState(@getInitialState())
          updatedUsedMovieList = [movie]
        else
          updatedUsedMovieList = @state.usedMovies.concat([movie])
        @setState(
          score: 0,
          movie: movie,
          isLoading: false,
          usedMovies: updatedUsedMovieList,
          isGuessable: true,
          totalMoviePages: totalPages
        )

  continue: ->
    console.log "continuing..."
    @setState(isLoading: true)
    prom = Api.getNextMovie(@state.currentActorId)
    prom.always =>
      console.log "done"
    prom.fail (err) ->
      console.log "handle error" + err
    prom.then (res) =>
      movieIndex = Math.floor(Math.random()*res.cast.length)
      while @movieHasBeenUsed(res.cast[movieIndex])
        movieIndex++
      @updateMovieInfo(res.cast[movieIndex].id)

  updateMovieInfo: (movieId) ->
    console.log "updating movie info..."
    prom = Api.getMovieInfo(movieId)
    prom.always =>
      console.log "done"
    prom.fail (err) ->
      console.log "handle error" + err
    prom.then (res) =>
      updatedUsedMovieList = @state.usedMovies.concat([res])
      @setState(
        movie: res,
        usedMovies: updatedUsedMovieList
      )

  isTooObscure: (popularity) ->
    if popularity < 0.1 then true else false

  isNotReleased: (date) ->
    if moment(date).isBefore(@state.today, 'day') then false else true

  isTooOld: (date) ->
    if moment(date).isBefore( moment().year(1975) , 'year') then true else false

  movieHasBeenUsed: (mov) ->
    used = false
    @state.usedMovies.forEach (el) ->
      if el.id is mov.id
        used = true
    used

  actorHasBeenUsed: (act) ->
    used = false
    if @state.usedActors.length > 0
      @state.usedActors.forEach (el) ->
        if el.id is act
          used = true
    used

  handleAnswerChange: (e) ->
    @clearResults()
    return unless e.target.value.length > 3
    guess = e.target.value
    prom = Api.getAutoCompleteOptions(encodeURI(guess))
    prom.always =>
      console.log "done"
    prom.fail (err) ->
      console.log "handle error" + err
    prom.then (res) =>
      if res.results.length > 0
        @appendResults(guess, res.results)
    @setState(answer: e.target.value)

  appendResults: (guess, results) ->
    @clearResults()
    i = 0
    while i < results.length and i < 3
      updatedSuggestedActorsList = @state.suggestedActors.concat([results[i]])
      i++
      @setState(suggestedActors: updatedSuggestedActorsList)
    @setState(showAutoComplete: true)

  clearResults: ->
    @setState(suggestedActors: [])

  handleAnswer: (e) ->
    e.preventDefault() if e
    guess = e.target.value || e.target.innerText
    console.log guess
    @setState(
      isGuessable: false ,
      showAutoComplete: false,
      isLoading: true,
      answer: guess
    )
    prom = Api.getMovieCredits(@state.movie.id.toString())
    prom.always =>
      console.log("done")
    prom.fail (err) ->
      console.log("handle error " + err)
    prom.then (res) =>
      isCorrect = @checkAnswer(res.cast, @state.answer)
      if isCorrect
        console.log "Correct, " + @state.answer + " was in " + @state.movie.title
        @getActorInfo(@state.currentActorId)
      else
        if @state.score > 5
          @setState(showSaveModal: true)

  checkAnswer: (arr, answer) ->
    console.log "Checking answer..."
    correct = false
    actorId = null
    arr.forEach (el) ->
      if el.name.toLowerCase() is answer.toLowerCase()
        actorId = el.id
        correct = true
    @setState({currentActorId: actorId })
    correct

  getActorInfo: (actor) ->
    prom = Api.getActorInfo(actor)
    prom.always =>
      console.log "done"
    prom.fail (err) ->
      console.log "handle error" + err
    prom.then (res) =>
      @updateActorState(res)

  updateActorState: (actor) ->
    if @actorHasBeenUsed(@state.currentActorId)
      @restart()
      return
    updatedUsedActorList = @state.usedActors.concat([actor])
    @setState({
      actor: actor,
      usedActors: updatedUsedActorList
    })
    @updateGame()

  updateGame: ->
    newScore = this.state.score + 1
    @setState({
      score: newScore
    })
    @continue()

  isNotAllowed: (idArray) ->
    if _.intersection(@state.disallowedCategories, idArray).length > 0 then return true else return false

  toggleModal: (visibility) ->
    @setState(showSaveModal: visibility)
    @restart()

  getInitialState: ->
    {
      isLoading: true,
      score: 0,
      answer: null,
      movie: {},
      actor: {},
      currentActorId: null,
      usedMovies: [],
      usedActors: [],
      suggestedActors: [],
      showAutoComplete: false,
      disallowedCategories: [10770, 99, 10769, 16, 10751],
      totalMoviePages: 1,
      isGuessable: true,
      showSaveModal: false,
      today: moment()
    }

  componentDidMount: ->
    console.log "mounted"
    prom = Api.getRandomMovie(@state.totalMoviePages)
    prom.always =>
      console.log("done")
      @setState(isLoading: false)
    prom.fail (err) ->
      console.log("handle error " + err)
    prom.then (res) =>
      totalPages = if res.total_pages > 1000 then Math.floor(Math.random()*1000) else res.total_pages
      movie = res.results[Math.floor(Math.random()*res.results.length)]
      if @isNotAllowed(movie.genre_ids)
        @restart()
        console.log "movie " + movie.title + " isn't up to snuff because it's a weird category"
      else if movie.original_language isnt "en"
        @restart()
        console.log "movie " + movie.title + " isn't up to snuff because it isn't in english"
      else if @isTooOld(movie.release_date)
        @restart
        console.log "movie " + movie.title + " isn't up to snuff because it came out before 1975"
      else
        updatedUsedMovieList = @state.usedMovies.concat([movie])
        @setState(
          movie: movie,
          usedMovies: updatedUsedMovieList
          isLoading: false,
          totalMoviePages: totalPages
        )

  componentDidUpdate: (prevProps, prevState) ->
    console.log "Component did update"
    if prevState.movie isnt @state.movie and not _.isEmpty(prevState.movie) and @state.score > 0
      if @isNotReleased(@state.movie.release_date)
        @continue()
        console.log "movie " + @state.movie.title + " isn't up to snuff because it hasn't come out yet"
      if @isTooObscure(@state.movie.popularity)
        @continue()
        console.log "movie " + @state.movie.title + " isn't up to snuff because of popularity"
      else if @isNotAllowed(@state.movie.genre_ids)
        @continue()
        console.log "movie " + @state.movie.title + " isn't up to snuff because it's a weird category"
      else if @state.movie.original_language isnt "en"
        @continue()
        console.log "movie " + @state.movie.title + " isn't up to snuff because it isn't in english"
      else
        @setState(
          isLoading: false,
          isGuessable: true
        )

  render: ->
    if @state.isLoading
      <Loader />
    else if @state.showSaveModal
      <div className="movie-game-container">
        <LeaderboardForm score={@state.score} visibility={@toggleModal}/>
      </div>
    else
      if @state.score > 0
        button = <FlatButton label="Give Up" primary={true} onClick={@giveUp}/>
      else
        button = <FlatButton label="Start Over" secondary={true} onClick={@restart}/>
      <div className="movie-game-container">
        <Card initiallyExpanded={true}>
          <CardHeader
            textStyle={{verticalAlign: "super"}}
            title="Score"
            avatar={<Avatar>{@state.score}</Avatar>}/>
          <Question hasPoster={@state.movie.backdrop_path} movie={@state.movie}/>
          <Answer isGuessable={@state.isGuessable} onChange={@handleAnswerChange} onEnterKeyDown={@handleAnswer}/>
          <AutoCompleteList actors={@state.suggestedActors} visible={@state.showAutoComplete} onClick={@handleAnswer}/>
          <CardActions style={textAlign: "right"} >
            {button}
          </CardActions>
        </Card>
      </div>
