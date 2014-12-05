require 'eventable'

class GameRuleException < StandardError
end

class Card
  RANKS = %w(2 3 4 5 6 7 8 9 10 J Q K A)
  SUITS = %w(Spade Heart Club Diamond)

  attr_accessor :rank, :suit

  def initialize(id)
    self.rank = RANKS[id % 13]
    self.suit = SUITS[id % 4]
  end

  def to_s
    "#{rank} #{suit}"
  end
end

class Deck
  attr_accessor :cards
  def initialize
    self.cards = (0..51).to_a.shuffle.collect { |id| Card.new(id) }
  end
end

class Player
  attr_accessor :name

  def initialize(name)
    self.name = name
  end
end

class Game
  include Eventable

  event :game_started
  event :player_joined

  def initialize(name)
    super()   # note BDM: Important to call with brackets, otherwise constructor args are passed and we get an exception

    @name = name
    @players = []
    @game_status = :lobby
  end

  def join(player_name)
    new_player = Player.new(player_name)
    @players << new_player

    fire_event(:player_joined, player_name, Time.now)

    new_player
  end

  def start
    raise GameRuleException, "Game can only be started in Lobby state" if @game_status != :lobby
    raise GameRuleException, "At least 2 players required to start the game!" if @players.length < 2

    @game_status = :playing

    fire_event(:game_started, @name, Time.now)
  end
end

class World
  def initialize
    @games = []
  end

  def create_game(name)
    new_game = Game.new(name)
    @games << new_game
    new_game
  end
end

class OutputController

  def on_game_started(name, time)
    puts "Game '#{name}' started at #{time}\n"
  end

  def on_player_joined(name, time)
    puts "Player '#{name}' joined at #{time}\n"
  end

end

w = World.new
my_game = w.create_game('Mijn spel')

out = OutputController.new

my_game.register_for_event(event: :game_started, listener: out, callback: :on_game_started)
my_game.register_for_event(event: :player_joined, listener: out, callback: :on_player_joined)

p1 = my_game.join('Jefke')
p2 = my_game.join('Joske')
my_game.start

# Wait just to be sure you see it happen
sleep(1)