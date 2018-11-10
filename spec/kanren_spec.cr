require "./spec_helper"

describe Kanren do
  it "binds a variable directly to a value" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.join(q, "Hello, World!")
    
    k.solutions.size.should eq 1
    solution = k.solutions.first
    
    solution.is_bound?(q).should eq true
    solution[q].should eq "Hello, World!"
  end
  
  it "binds a variable transitively to a value" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.fresh(2) do |(a, b)|
      k.join(q, a)
      k.join(a, b)
      k.join(b, "Hello, World!")
    end
    
    k.solutions.size.should eq 1
    solution = k.solutions.first
    
    solution.is_bound?(q).should eq true
    solution[q].should eq "Hello, World!"
  end
  
  it "leaves a variable unbound due to being unmentioned" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.fresh(2) do |(a, b)|
      k.join(a, b)
      k.join(b, "Hello, World!")
    end
    
    k.solutions.size.should eq 1
    solution = k.solutions.first
    
    solution.is_bound?(q).should eq false
    expect_raises(KeyError) { solution[q] }
  end
  
  it "leaves a variable unbound due to being circularly unified" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.fresh(2) do |(a, b)|
      k.join(q, a)
      k.join(a, b)
    end
    
    k.solutions.size.should eq 1
    solution = k.solutions.first
    
    solution.is_bound?(q).should eq false
    expect_raises(KeyError) { solution[q] }
  end
  
  it "fails to solve for directly conflicting values" do
    k = Kanren::Solver(String).new
    
    k.join("Hello", "World")
    
    k.solutions.size.should eq 0
  end
  
  it "fails to solve for transitively conflicting values" do
    k = Kanren::Solver(String).new
    
    k.fresh(2) do |(a, b)|
      k.join(a, "Hello")
      k.join(b, "World")
      k.join(a, b)
    end
    
    k.solutions.size.should eq 0
  end
  
  it "solves branched direct assignments" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.branch(2) do |(k0, k1)|
      k0.join(q, "Hello")
      k1.join(q, "World")
    end
    
    k.solutions.size.should eq 2
    k.solutions[0][q].should eq "Hello"
    k.solutions[1][q].should eq "World"
  end
  
  it "solves branched transitive assignments" do
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.fresh(2) do |(a, b)|
      k.branch(2) do |(k0, k1)|
        k0.join(a, "Hello")
        k0.join(b, q)
        
        k1.join(b, "World")
        k1.join(a, q)
      end
      k.join(a, b)
    end
    
    k.solutions.size.should eq 2
    k.solutions[0][q].should eq "Hello"
    k.solutions[1][q].should eq "World"
  end
  
  it "solves for limited recursion within a finite domain" do
    # For a given "a" and "b" in a finite domain (zero through four),
    # require "b" to be the natural number immediately following "a".
    succ = ->(k : Kanren::Solver(String), a : Kanren::Var, b : Kanren::Var) do
      k.branch(4) do |(k0, k1, k2, k3)|
        k0.tap do |k|
          k.join(a, "zero")
          k.join(b, "one")
        end
        
        k1.tap do |k|
          k.join(a, "one")
          k.join(b, "two")
        end
        
        k2.tap do |k|
          k.join(a, "two")
          k.join(b, "three")
        end
        
        k3.tap do |k|
          k.join(a, "three")
          k.join(b, "four")
        end
      end
    end
    
    # For a given "a" and "b" in a finite domain (zero through four),
    # require "b" to be one of the natural numbers that is less than "a",
    # using finite recursion over this function as one of the two branches.
    lt = ->(k : Kanren::Solver(String), a : Kanren::Var, b : Kanren::Var) { }
    lt = ->(k : Kanren::Solver(String), a : Kanren::Var, b : Kanren::Var) do
      k.branch(2) do |(k0, k1)|
        k0.tap do |k|
          succ.call(k, a, b)
        end
        
        k1.tap do |k|
          k.fresh(1) do |(c)|
            succ.call(k, a, c)
            lt.call(k, c, b)
          end
        end
      end
    end
    
    # Find the non-negative natural numbers that are less than three.
    k = Kanren::Solver(String).new
    q = k.query_var
    
    k.fresh(1) do |(a)|
      k.join(a, "three")
      lt.call(k, q, a)
    end
    
    k.solutions.size.should eq 3
    k.solutions.map(&.[q]).sort.should eq ["one", "two", "zero"]
  end
end
