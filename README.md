# Delphi.Injection
This is a framework only for dependency injection for Delphi

# Geting started

This dependency injector register the type and all interfaces that implemented by this type, is no necessary do register the implementation of every interface of an class.
If you use the querey interface procedure, it is necessary to register the implementation of the specific interface in the registry.
The register of all anotated classes are make in the first call of GetService function, or calling RegisterAllType in the main class.
You can register a type by name and resolver the service by name. This name must be unique in all registered types.

# ToDo
- Register type
- Register type attribute
- Register type by name of service
- Register type with a constructor delegate
- Get service resolver
- Get service by name
- Get service by type
- Implements register
- Implements attribute
- When register an attribute with implements, can't register automatic the specified type
