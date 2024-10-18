cmake_minimum_required(VERSION 3.25)

# Служебные функции cmake

#[====[.rst:
    **Описание**

    Функция предназначена для проверки входных параметров самописных cmake функций.
    Данная функция должна вызываться после парсинга параметров исследуемой функции.

    В качестве аргументов должны быть переданы:
        - префикс парсинга параметров исследуемой функции;
        - список обязательных параметров исследуемой функции, для которых проверяется наличие хотя бы одного значения;
        - (опционально) список опциональных параметров исследуемой функции, для которых, если они есть,
                        проверяется наличие хотя бы одного значения;
        - (опционально) список взаимно исключающих флагов, где проверяется, что в пределах вызова исследуемой функции
                        максимум был использован один такой флаг.

    В случае обнаружения ошибки функция прерывает работу и выводит соответствующее сообщение.

    Функция проверяет свою сигнатуру.

    **Функция**::

     __check_parameters__(PREFIX <prefix>
                          PARAMETERS <par1> <par2> ...
                          [OPTIONAL_PARAMETERS <optPar1> <optPar2> ...]
                          [EXCLUSIVE_FLAGS <flag1> <flag2> ...])

    **Аргументы**

    -              ``PREFIX`` - Префикс парсинга параметров исследуемой функции
    -          ``PARAMETERS`` - Список обязательных параметров
    - ``OPTIONAL_PARAMETERS`` - (опционально) Список опциональных параметров
    -     ``EXCLUSIVE_FLAGS`` - (опционально) Список взаимно исключающих флагов
#]====]

function(__check_parameters__)

    # Если это старт функции
    if(NOT DEFINED __SELF_CHECKING__)

        # Отметить начало этапа самопроверки
        set(__SELF_CHECKING__ True)

        # Задать префикс парсинга
        set(__PARSING_PREFIX__ "__FUNCTION_PARAMETERS_CHECKING_PREFIX__")

        # Парсить аргументы функции (для всех проверок одного раза достаточно)
        cmake_parse_arguments("${__PARSING_PREFIX__}" "" "PREFIX" "PARAMETERS;OPTIONAL_PARAMETERS;EXCLUSIVE_FLAGS" "${ARGN}")

        # Запустить самопроверку (одноуровневая рекурсия)
        __check_parameters__()

        # Отметить завершение этапа самопроверки
        set(__SELF_CHECKING__ False)

    endif()

    # В данный момент ИДЕТ самопроверка?
    if(${__SELF_CHECKING__})

        # Задать префикс вызывающей функции как префикс парсинга
        set(__FUNCTION_PREFIX__ "${__PARSING_PREFIX__}")

        # Задать обязательные параметры для проверки
        set(__REQUIRED_PARAMETERS__ "PREFIX;PARAMETERS")

        # Задать опциональные параметры для проверки
        set(__OPTIONAL_PARAMETERS__ "OPTIONAL_PARAMETERS;EXCLUSIVE_FLAGS")

    else()

        # Взять префикс вызывающей функции из значения аргумента
        set(__FUNCTION_PREFIX__ "${${__PARSING_PREFIX__}_PREFIX}")

        # Взять обязательные параметры для проверки из значения аргумента
        set(__REQUIRED_PARAMETERS__ "${${__PARSING_PREFIX__}_PARAMETERS}")

        # Взять опциональные параметры для проверки из значения аргумента
        set(__OPTIONAL_PARAMETERS__ "${${__PARSING_PREFIX__}_OPTIONAL_PARAMETERS}")

        # Для каждого возможного уникального флага
        foreach(__FLAG__ ${${__PARSING_PREFIX__}_EXCLUSIVE_FLAGS})

            # Если флаг активен -> запомнить его
            if(${__FUNCTION_PREFIX__}_${__FLAG__})
                list(APPEND __FLAGS_NAMES__ "${__FLAG__}")
            endif()

        endforeach()

        # Посчитать количество активных флагов
        list(LENGTH __FLAGS_NAMES__ __ACTIVE_FLAGS_COUNT__)

        # Проверить, что активно не более одного флага
        if(${__ACTIVE_FLAGS_COUNT__} GREATER 1)
            message(FATAL_ERROR "Флаги не могут быть использованны одновременно: ${__FLAGS_NAMES__}")
        endif()

    endif()

    # Для каждого параметра (обязательного и опционального)
    foreach(__PAR__ ${__REQUIRED_PARAMETERS__} ${__OPTIONAL_PARAMETERS__})

        # Проверить, что для параметра задано значение
        list(FIND "${__FUNCTION_PREFIX__}_KEYWORDS_MISSING_VALUES" ${__PAR__} __ARG_INDEX__)
        if(NOT ${__ARG_INDEX__} EQUAL -1)
            message(FATAL_ERROR "У параметра ${__PAR__} должно быть задано значение")
        endif()

    endforeach()

    # Для каждого обязательного параметра
    foreach(__PAR__ ${__REQUIRED_PARAMETERS__})

        # Проверить, что параметр определен
        if(NOT DEFINED "${__FUNCTION_PREFIX__}_${__PAR__}")
            message(FATAL_ERROR "Параметр ${__PAR__} должен быть определен")
        endif()

    endforeach()

    # Проверить наличие лишних параметров
    if(DEFINED "${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS")
        message(FATAL_ERROR "Присутствуют лишние параметры: ${${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS}")
    endif()

endfunction()

#[====[.rst:

    **Описание**

    Функция предназначена для проверки существования директорий.

    В качестве аргумента должны быть переданы пути к проверяемым директориям.

    В случае обнаружения ошибки функция прерывает работу и выводит соответствующее сообщение.

    Функция проверяет свою сигнатуру.

    **Функция**::

     __check_directories_exists__(DIRS <dir1> <dir2> ...)

    **Аргументы**

    - ``DIRS`` - Пути к проверяемым директориям

#]====]

function(__check_directories_exists__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__DIRECTORIES_EXISTENCE_CHECKING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__MULTIPLE_VALUE_ARGS__ "DIRS")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}" "" "" "${__MULTIPLE_VALUE_ARGS__}" "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}" PARAMETERS "${__MULTIPLE_VALUE_ARGS__}")

    # Для каждой директории
    foreach(__DIR__ ${${__PARSING_PREFIX__}_DIRS})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Проверить что директория существует
        if (NOT IS_DIRECTORY "${__PATH_TO_DIR__}")
            message(FATAL_ERROR "Не существует директории: ${__PATH_TO_DIR__}")
        endif()

    endforeach()

endfunction()

#[====[.rst:

    **Описание**

    Функция предназначена для поиска и формирования списка поддиректорий для заданной директории.
    По умолчанию поиск будет осуществляться рекурсивно до нахождения директорий на всех уровнях вложенности.
    Опционально можно задать максимальную глубину вложенности, до которой будет осуществляться поиск.
    По умолчанию исходная директория также добавляется в итоговый список. Опционально это можно запретить.

    В качестве аргументов должны быть переданы:
        - исходная директория, для которой будет осуществлен поиск вложенных директорий;
        - имя выходной переменной, в которую будет записан список найденных директорий;
        - (опционально) уровень вложенности, до которого следует искать поддиректории, (не должен быть отрицательным)
                        (0 - исходная директория, 1 - первый уровень поддиректорий, ...);
        - (опционально) флаг запрета добавления исходной директории в выходной список.

    Функция проверяет свою сигнатуру.

    **Функция**::

     __collect_subdirectories__(DIRECTORY <dir>
                                OUT_VAR <out-var>
                                [MAX_DEPTH <max-depth>]
                                [NO_ROOT])

    **Аргументы**

    - ``DIRECTORY`` - Исходная директория
    -   ``OUT_VAR`` - Выходная переменная
    - ``MAX_DEPTH`` - (опционально) Максимальная глубина вложенности
    -   ``NO_ROOT`` - (опционально) Не добавлять исходную директорию

#]====]

function(__collect_subdirectories__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__SUBDIRECTORIES_COLLECTING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__FLAGS__ "NO_ROOT")
    set(__ONE_VALUE_ARGS__ "DIRECTORY" "OUT_VAR")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "MAX_DEPTH")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}" "${__FLAGS__}" "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}" "" "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}" PARAMETERS "${__ONE_VALUE_ARGS__}" OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}")

    # Взять исходную директорию из аргумента
    set(__ROOT_DIR__ "${${__PARSING_PREFIX__}_DIRECTORY}")

    # Проверить существование исходной директории
    __check_directories_exists__(DIRS "${__ROOT_DIR__}")

    # Задать переменную для записи всех найденных файлов и директорий
    set(__RESULT__)

    # В случае, если НЕ задана максимальная глубина
    if(NOT DEFINED "${__PARSING_PREFIX__}_MAX_DEPTH")

        # Найти на всех уровнях файлы с директориями
        file(GLOB_RECURSE __SEARCH_RESULT__
            LIST_DIRECTORIES true
            ${__ROOT_DIR__}/*)

        # Для всех найденных файлов с директориями
        foreach(__ELEM__ ${__SEARCH_RESULT__})

            # Запомнить директории
            if (IS_DIRECTORY ${__ELEM__})
                list(APPEND __RESULT__ ${__ELEM__})
            endif()

        endforeach()

    else()

        # Взять значение максимальной глубины из аргумента
        set(__MAX_DEPTH__ "${${__PARSING_PREFIX__}_MAX_DEPTH}")

        # Проверить значение максимальной глубины
        if(NOT ${__MAX_DEPTH__} MATCHES "^(0|[1-9][0-9]*)$")
            message(FATAL_ERROR "Значение MAX_DEPTH должно быть целым беззнаковым числом: ${__MAX_DEPTH__}")
        endif()

        # Если еще не конец
        if(NOT ${__MAX_DEPTH__} EQUAL 0)

            # Найти на текущем уровне все файлы с директориями
            file(GLOB __SEARCH_RESULT__
                LIST_DIRECTORIES true
                ${__ROOT_DIR__}/*)

            # Уменьшить уровень глубины
            math(EXPR __REDUCED_MAX_DEPTH__ "${__MAX_DEPTH__} - 1")

            # Для найденных файлов с директориями
            foreach(__ELEM__ ${__SEARCH_RESULT__})

                # Если это директория
                if (IS_DIRECTORY ${__ELEM__})

                    # Рекурсивно запустить поиск директорий (включая ее саму как исходную) на следующем уровне
                    __collect_subdirectories__(DIRECTORY "${__ELEM__}" OUT_VAR __CURRENT_OUT_VAR__ MAX_DEPTH "${__REDUCED_MAX_DEPTH__}")

                    # Добавить найденные директории к результату
                    list(APPEND __RESULT__ "${__CURRENT_OUT_VAR__}")

                endif()

            endforeach()

        endif()

    endif()

    # Взять имя выходной переменной из аргумента
    set(__OUT_VAR__ "${${__PARSING_PREFIX__}_OUT_VAR}")

    # Записать в выходную переменную все собранные директории
    set(${__OUT_VAR__} "${__RESULT__}")

    # Если не было специального флага -> добавить исходную директорию в итоговый список
    if(NOT ${__PARSING_PREFIX__}_NO_ROOT)
        list(APPEND ${__OUT_VAR__} "${__ROOT_DIR__}")
    endif()

    # Вернуть значение выходной переменной
    return(PROPAGATE ${__OUT_VAR__})

endfunction()
