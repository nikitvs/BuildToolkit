cmake_minimum_required(VERSION 3.20)

# Подключить вспомогательные функции
include(${CMAKE_CURRENT_LIST_DIR}/_auxiliary.cmake)

# Собрать все директории модулей (включая текущую директорию)
__collect_subdirectories__(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} OUT_VAR __CMAKE_MODULES_DIRS__)

# Добавить директории модулей cmake в список стандартных путей
list(APPEND CMAKE_MODULE_PATH ${__CMAKE_MODULES_DIRS__})
