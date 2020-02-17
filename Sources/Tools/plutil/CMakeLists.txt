add_executable(plutil
  main.swift)
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_options(plutil PRIVATE LINKER:/ignore:4286)
endif()
target_link_libraries(plutil PRIVATE
  Foundation)
set_target_properties(plutil PROPERTIES
  INSTALL_RPATH "$ORIGIN/../lib/swift/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>")


set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS plutil)
install(TARGETS plutil
  DESTINATION ${CMAKE_INSTALL_BINDIR})
