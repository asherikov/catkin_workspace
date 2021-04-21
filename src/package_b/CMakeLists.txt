cmake_minimum_required(VERSION 3.0.2)
project(package_b)

find_package(catkin REQUIRED COMPONENTS package_a staticoma)

staticoma()

catkin_package(
#  INCLUDE_DIRS include
#  LIBRARIES package_a
  CATKIN_DEPENDS package_a
#  DEPENDS system_lib
)

staticoma_export("config/extended_config.yaml")

staticoma_compose(
    merged_config.yaml
    package_a base_config.yaml
    package_b "config/extended_config.yaml"
)

foreach(DIR launch)
    install(DIRECTORY ${DIR}
        DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
        USE_SOURCE_PERMISSIONS
    )
endforeach()
