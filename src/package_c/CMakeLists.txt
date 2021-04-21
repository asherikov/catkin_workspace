cmake_minimum_required(VERSION 3.0.2)
project(package_c)

find_package(catkin REQUIRED COMPONENTS
    roscpp
    package_b
    staticoma
    ariles2_yamlcpp_catkin
)

staticoma()

catkin_package(
#  INCLUDE_DIRS include
#  LIBRARIES package_c
#  CATKIN_DEPENDS other_catkin_pkg
#  DEPENDS system_lib
)

staticoma_compose(
    merged_config.yaml
    ARRAY_MERGE_STRATEGY append
#    STRICT # would fail
    package_a base_config.yaml
    package_b extended_config.yaml
)

staticoma_compose(
    merged_config1.yaml
#    STRICT # would fail
    package_a base_config.yaml
    package_b merged_config.yaml
)

staticoma_compose(
    merged_config5.yaml
    STRICT
    package_c merged_config1.yaml
    package_c merged_config.yaml
)

staticoma_compose(
    merged_config2.yaml
    STRICT
    package_c merged_config.yaml
    package_c merged_config1.yaml
)

staticoma_compose(
    merged_config3.yaml
    STRICT
    package_c merged_config1.yaml
    package_a base_config.yaml
)

staticoma_compose(
    merged_config4.yaml
    STRICT
    package_c merged_config1.yaml
    package_b extended_config.yaml
)


include_directories(
    SYSTEM ${catkin_INCLUDE_DIRS}
)
add_executable(node src/node.cpp)
target_link_libraries(node
    ${catkin_LIBRARIES}
)
install(TARGETS node
    ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
    LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
    RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

foreach(DIR launch)
    install(DIRECTORY ${DIR}
        DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
        USE_SOURCE_PERMISSIONS
    )
endforeach()
