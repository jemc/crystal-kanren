require "immutable"

struct Kanren::State(T)
  property redirects
  property bindings
  
  def initialize
    @redirects = Immutable::Map(Var, Var).new
    @bindings = Immutable::Map(Var, T).new
  end
  
  # Return true if the given Var is bound to a value in this State.
  def is_bound?(var): Bool
    # TODO: use has_key? after doing a PR to the `immutable` library.
    bindings[_follow_redirects(var)]
    true
  rescue KeyError
    false
  end
  
  # Return the value bound to the given Var, or raise KeyError if unbound.
  def [](var): T
    bindings[_follow_redirects(var)]
  end
  
  # Return the value bound to the given Var, or nil if unbound.
  def []?(var): T?
    bindings[_follow_redirects(var)]?
  end
  
  # Return the stream of states in which the given two Vars are unified
  # (constrained to have the same value). If this is logically inconsistent
  # with the current state, the returned stream of states will be empty.
  def unify_vars(a : Var, b : Var): Iterator(State(T))
    a = _follow_redirects(a)
    b = _follow_redirects(b)
    
    begin; a_value = bindings[a]
      begin; b_value = bindings[b]
        unify_values(a_value, b_value)
      rescue KeyError
        _with_bind(b, a_value)
      end
    rescue KeyError
      begin; b_value = bindings[b]
        _with_bind(a, b_value)
      rescue KeyError
        _with_redirect(a, b)
      end
    end
  end
  
  # Return the stream of states in which the given Var has been unified with
  # the given value. If this is logically inconsistent with the current state,
  # the returned stream of states will be empty.
  def unify_value(var : Var, value : T): Iterator(State(T))
    var = _follow_redirects(var)
    
    begin; existing_value = bindings[var]
      unify_values(existing_value, value)
    rescue KeyError
      _with_bind(var, value)
    end
  end
  
  # Return the stream of states in which the given two values are unified
  # (constrained to be the same value). If the values are not equal,
  # the returned stream of states will be empty.
  def unify_values(a_value : T, b_value : T): Iterator(State(T))
    if a_value == b_value
      [self].each
    else
      ([] of State(T)).each
    end
  end
  
  # Return a stream containing a copy of this state in which a redirect entry
  # has been added, pointing from the first Var to the second Var. It is
  # assumed that both have been confirmed to have no bindings, and that both
  # have already had their redirects followed to the final Var in the chain.
  private def _with_redirect(a, b)
    copy = self
    copy.redirects = copy.redirects.set(a, b)
    [copy].each
  end
  
  # Return a stream containing a copy of this state in which a binding entry
  # has been added, assigning the given value to var. It is assumed that var
  # has been confirmed to have no bindings, and that it already had its
  # redirects followed to the final var in the chain.
  private def _with_bind(var, value)
    copy = self
    copy.bindings = copy.bindings.set(var, value)
    [copy].each
  end
  
  # Follow the chain of redirects originating from the given Var,
  # until we have reached the final canonical Var.
  private def _follow_redirects(var)
    loop do
      var = redirects[var] rescue break
    end
    var
  end
end
