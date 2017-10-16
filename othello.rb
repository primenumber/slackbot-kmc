class Othello
  EMPTY = 0
  BLACK = 1
  WHITE = 2
  def initialize
    @board = Array.new(8) {|i| Array.new(8, EMPTY)}
    @board[3][3] = WHITE
    @board[3][4] = BLACK
    @board[4][3] = BLACK
    @board[4][4] = WHITE
    @turn = BLACK
  end
  def movable(x, y)
    return false if @board[y][x] != EMPTY
    dx = [1, 1, 1, 0, -1, -1, -1, 0]
    dy = [1, 0, -1, -1, -1, 0, 1, 1]
    8.times {|i|
      (1..8).each {|j|
        nx = x + j * dx[i]
        ny = y + j * dy[i]
        break if nx < 0 || ny < 0 || nx >= 8 || ny >= 8
        if @board[ny][nx] == @turn then # opponent's stone
          return true if j > 1
          break
        end
        break if @board[ny][nx] == EMPTY
      }
    }
    return false
  end
  def movable?
    8.times do |x|
      8.times do |y|
        return true if movable(x, y)
      end
    end
    return false
  end
  def move(x, y)
    raise "cannot move #{x} #{y}" if !movable(x, y)
    dx = [1, 1, 1, 0, -1, -1, -1, 0]
    dy = [1, 0, -1, -1, -1, 0, 1, 1]
    8.times {|i|
      (1..8).each {|j|
        nx = x + j * dx[i]
        ny = y + j * dy[i]
        break if nx < 0 || ny < 0 || nx >= 8 || ny >= 8
        if @board[ny][nx] == @turn then # opponent's stone
          if j > 1 then
            (1...j).each {|k|
              kx = x + k * dx[i]
              ky = y + k * dy[i]
              @board[ky][kx] = @turn
            }
          end
          break
        end
        break if @board[ny][nx] == EMPTY
      }
    }
    @board[y][x] = @turn
    next_turn
  end
  def pass
    next_turn
  end
  def next_turn
    @turn = 3 - @turn
  end
  def hand_to_xy(hand)
    x = hand[0].ord - 'a'.ord
    y = hand[1].ord - '1'.ord
    raise "invalid hand #{hand}" if x < 0 || y < 0 || x >= 8 || y >= 8
    return x, y
  end
  def think
    result = `/home/prime/issen/think.sh '#{to_base81}'`.split(' ')
    if result[0] == "ps" then
      pass
      return result 
    end
    x, y = hand_to_xy(result[0])
    move(x, y)
    return result 
  end
  def to_s 
    res = "+abcdefgh\n"
    @board.each_with_index {|l,index|
      res += "#{(index+1)}"
      l.each {|s|
        case s
        when EMPTY
          res += "."
        when BLACK
          res += "x"
        when WHITE
          res += "o"
        end
      }
      res += "\n"
    }
    return res
  end
  def fix(stone)
    if stone == EMPTY then
      return 0 
    end
    if stone == @turn then
      return 1
    end
    return 2
  end
  def to_base81_chr(ary)
    idx = fix(ary[3]) * 32 + fix(ary[2]) * 9 + fix(ary[1]) * 3 + fix(ary[0]) + 33
    c = idx.chr
    case c
    when "'"
      return "'\"'\"'"
    else
      return c
    end
  end
  def to_base81
    res = ""
    @board.each {|l|
      res += to_base81_chr(l[0...4])
      res += to_base81_chr(l[4...8])
    }
    return res
  end
end
