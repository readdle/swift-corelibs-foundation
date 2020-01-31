
add_executable(GenerateTestFixtures
  GenerateTestFixtures/main.swift
  GenerateTestFixtures/Utilities.swift
  ../../TestFoundation/FixtureValues.swift)
if(CMAKE_SYSTEM_NAME STREQUAL Windows)
  target_link_options(GenerateTestFixtures PRIVATE LINKER:/ignore:4286)
endif()
target_link_libraries(GenerateTestFixtures PRIVATE
  Foundation)
