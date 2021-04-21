cmake_minimum_required(VERSION 3.0.2)
project(package_a)

find_package(catkin REQUIRED COMPONENTS staticoma)

staticoma()

catkin_package(
#  INCLUDE_DIRS include
#  LIBRARIES package_a
#  CATKIN_DEPENDS other_catkin_pkg
#  DEPENDS system_lib
)

staticoma_export("config/base_config.yaml")

