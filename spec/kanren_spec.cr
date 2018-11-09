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
end
