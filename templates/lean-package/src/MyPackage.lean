import IPLD


namespace MyPackage
def sayHello (name : String) : IO Unit := do
  print! "Hello {name}!"

#eval "Hello, world!"
end MyPackage
