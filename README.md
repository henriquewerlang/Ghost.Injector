# Ghost.Injector
This is a framework only for dependency injection for Delphi

# Geting started

This dependency injector uses Delphi's full RTTI potential to locate and create the types requested by the program. You don't need to register all the types you'll use in your application unless you need a specific constructor that requires a special startup.
The hierarchy of declared constructors is respected, and the object is not created at any cost.
You are allowed to register the same type and service name multiple times if you need to, the single registration of these types is not required.

# ToDo
- Resolve all type of constructor params
- Singleton implementation
- Field injection by annotation
