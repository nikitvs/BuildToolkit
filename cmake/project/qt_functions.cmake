cmake_minimum_required(VERSION 3.25)

# Функции и настройки для работы с Qt

# Подключить служебный модуль
include(_auxiliary)

# Настроить MOC для Qt
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Найти пакеты Qt
find_package(QT NAMES Qt6 Qt5 REQUIRED)

#[====[.rst:

    **Описание**

    Найти и подключить целевому таргету указанные библиотеки Qt.
    Опционально можно указать версию пакета Qt, из которого будут браться библиотеки.
    По умолчанию берется наибольшая возможная версия.
    Также опционально можно указать модификатор видимости для внешних таргетов.
    По умолчанию берется модификатор PUBLIC.

    В качестве аргументов должны быть переданы:
        - целевой таргет для подключения библиотек;
        - список подключаемых библиотек;
        - (опционально) требуемая версия пакета Qt;
        - (опционально) модификатор видимости для внешних таргетов.

    Функция проверяет свою сигнатуру.

    **Функция**::

     assign_qt_libs_to_target(TARGET <target>
                              QT_LIBS <lib1> <lib2> ...
                              [VERSION <version>]
                              [PUBLIC | PRIVATE | INTERFACE])

    **Аргументы**

    -                       ``TARGET`` - Целевой таргет
    -                      ``QT_LIBS`` - Список библиотек Qt
    -                      ``VERSION`` - (опционально) версия пакета Qt
    - ``PUBLIC | PRIVATE | INTERFACE`` - (опционально) Модификатор доступа

#]====]

function(assign_qt_libs_to_target)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__QT_LIBS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "QT_LIBS")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "VERSION")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}"
                         EXCLUSIVE_FLAGS "${__EXCLUSIVE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование таргета
    if (NOT TARGET "${__TARGET__}")
        message(FATAL_ERROR "Не существует таргета: ${__TARGET__}")
    endif()

    # Если задана версия
    if(DEFINED "${__PARSING_PREFIX__}_VERSION")
        # Взять версию из аргумента
        set(__VERSION__ "${${__PARSING_PREFIX__}_VERSION}")
    else()
        # Задать наибольшую возможную версию
        set(__VERSION__ "${QT_VERSION_MAJOR}")
    endif()

    # Задать текущий модификатор в зависимости аргументов
    if (${__PARSING_PREFIX__}_PUBLIC)
        set(__MODIFIER__ "PUBLIC")
    elseif (${__PARSING_PREFIX__}_PRIVATE)
        set(__MODIFIER__ "PRIVATE")
    elseif (${__PARSING_PREFIX__}_INTERFACE)
        set(__MODIFIER__ "INTERFACE")
    else()
        # Значение по умолчанию
        set(__MODIFIER__ "PUBLIC")
    endif()

    # Найти библиотеки Qt
    find_package("Qt${__VERSION__}" COMPONENTS "${${__PARSING_PREFIX__}_QT_LIBS}" REQUIRED)

    # Подключить библиотеки Qt
    foreach(__LIB__ ${${__PARSING_PREFIX__}_QT_LIBS})
        target_link_libraries("${${__PARSING_PREFIX__}_TARGET}" ${__MODIFIER__} "Qt${__VERSION__}::${__LIB__}")
    endforeach()

endfunction()
