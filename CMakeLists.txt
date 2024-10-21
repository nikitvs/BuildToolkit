cmake_minimum_required(VERSION 3.25)

# Задать проект
project(BuildToolkit)

# Подключить директорию cmake функций
add_subdirectory(cmake)

# "Вытащить наружу" пути к модулям cmake
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
