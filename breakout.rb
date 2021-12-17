#!/usr/bin/env ruby


require 'bundler/setup'
Bundler.require

require_relative 'intcode'

module InputSource
  class Joystick

    def initialize(paddle, ball)
      super()
      @paddle = paddle
      @ball = ball
    end

    def deliver
      # sleep 0.07
      @ball.first <=> @paddle.first
    end
  end
end

module OutputSink
  class VDU < BufferedOutput
    def initialize(paddle, ball)
      super()
      @paddle = paddle
      @ball = ball
    end

    def receive(value)
      super
      draw(values.slice!(0,3)) if values.length >= 3
    end

    def sprites
      @sprites ||= {
        empty: 0,
        wall: 1,
        block: 2,
        paddle: 3,
        ball: 4
      }
    end

    def draw(values)
      pastel = Pastel.new
      cursor = TTY::Cursor
      score = 0

      unless @is_screen_cleared
        print cursor.clear_screen
        @is_screen_cleared = true
      end

      values.each_slice(3) do |x, y, sprite|
        if x == -1 && y == 0
          print cursor.column(1)
          print cursor.row(25)
          score = sprite.to_s.rjust(5, '0')
          print pastel.bold.white.on_bright_blue("Score: #{score}".center(36))
          next
        end

        print cursor.column(x+1)
        print cursor.row(y+1)

        case sprite
        when sprites[:empty] then print ' '
        when sprites[:wall] then print pastel.yellow('░')
        when sprites[:block] then print pastel.cyan('█')
        when sprites[:paddle] 
          print pastel.green.bold('━')
          @paddle[0], @paddle[1] = x,y
        when sprites[:ball] 
          print pastel.red('●')
          @ball[0], @ball[1] = x,y
        end
      end
    # sleep 0.009
    end

  end
end


class Breakout

  sprites = {
    empty: 0,
    wall: 1,
    block: 2,
    paddle: 3,
    ball: 4
  }

  attr_reader :intputer, :output, :input
  attr_accessor :ball_location

  def initialize
    paddle = [0,0]
    ball = [0,0]
    @output = OutputSink::VDU.new(paddle, ball)
    @input = InputSource::Joystick.new(paddle, ball)
    @intputer = Intputer.new(load, input: @input, output: @output)
  end

  def load
    File.read('input.txt').split(',').map(&:to_i)
  end

  def play
    cursor = TTY::Cursor
    print cursor.hide
    intputer.execute
    puts cursor.show
    puts
  end
end


Breakout.new.play
