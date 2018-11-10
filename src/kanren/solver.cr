class Kanren::Solver(T)
  # TODO: Use Iterator(State(T)) instead, when crystal-lang#7044 is fixed?
  @states : Array(State(T))
  
  def initialize(@states = [State(T).new])
  end
  
  def solutions
    @states
  end
  
  def query_var
    Var.new
  end
  
  def fresh(count)
    return if @states.empty?
    vars = count.times.map { Var.new }.to_a
    yield vars
    # TODO: hygiene - forget fresh vars from state after block?
    nil
  end
  
  def branch(count)
    return if @states.empty?
    branches = count.times.map { self.class.new(@states) }.to_a
    yield branches
    # TODO: consider cases where some confused soul modified this main solver?
    @states = branches.flat_map(&.solutions)
    nil
  end
  
  def member(var : Var, *values)
    return if @states.empty?
    @states = values.flat_map do |value|
      @states.flat_map { |s| s.unify_value(var, value) }
    end
    nil
  end
  
  def join(a : Var, b : Var)
    return if @states.empty?
    @states = @states.flat_map { |s| s.unify_vars(a, b) }
    nil
  end
  
  def join(a : T, b : T)
    return if @states.empty?
    @states = @states.flat_map { |s| s.unify_values(a, b) }
    nil
  end
  
  def join(var : Var, value : T)
    return if @states.empty?
    @states = @states.flat_map { |s| s.unify_value(var, value) }
    nil
  end
end
