with_defaults = require './with_defaults'

# "Fancy" version of Object.defineProperty that stores and applies a given
# default value
define_uncurried = (object, name, descriptor) ->
  # A default value for accessors might be added, however it has to be removed
  # from the descriptor before calling Object.defineProperty.
  # According to the Mozilla documentation of defineProperty, accessor
  # descriptors may not have a default value.
  #
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty
  if descriptor.is_accessor?
    value = descriptor.value
    delete descriptor.value

  Object.defineProperty object, name, descriptor

  # Apply default value 
  object[name] = value if descriptor.is_accessor?

module.exports =
  define: (object, name, descriptor) ->
    # Return a partially applied function when only the object is given
    # 
    # This enables usage as such:
    #
    # P = require './define'
    # {ReadOnly, Data, Descriptor} = P
    #
    # o = {}
    #
    # define = P.define o
    #
    # define 'readonly', ReadOnly Data Descriptor value: 10
    # define 'writable',          Data Descriptor value: 20
    #

    return (n, d) -> define_uncurried object, n, d   if 1 == arguments.length
    return define_uncurried object, name, descriptor if 3 == arguments.length
    
    throw new Error 'Wrong number of arguments given. Only one or three arguments allowed.'

  # Returns a descriptor holding the given getter and/or setter functions, as
  # well as a boolean property `is_accessor` set to true.
  #
  # Descriptor                     -> Descriptor
  # Function                       -> Descriptor 
  # Descriptor, Function           -> Descriptor
  # Descriptor, Function, Function -> Descriptor
  # undefined, null                -> Descriptor
  Accessor: (args...) ->
    options = { is_accessor: true }

    return options unless args.length

    options = with_defaults args[0], options if T.is_object args[0]

    options.get = do args.shift if T.is_function args[0]
    options.set = do args.shift if T.is_function args[0]

    options

  Descriptor: (options = {}) ->
    with_defaults options,
      configurable: true
      enumerable:   false

  Data: (options = {}) ->
    with_defaults options,
      writable: true
      is_data:  true

  ReadOnly: (options = {}) ->
    if options.is_accessor?
      console.log 'WARNING: ReadOnly is only applicable to data descriptors, given: ', options

    with_defaults options,
      writable: false
      value:    null
      is_data:  true

  Enumerable: (options = {}) ->
    with_defaults options, enumerable: true
