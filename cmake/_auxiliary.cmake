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

    В случае обнаружения ошибки данная функция прерывает работу и выводит соответствующее сообщение.
    Функция рекурсивно проверяет сама себя, контролируя переданные в нее аргументы.

    **Функция**::

     __check_parameters__(PREFIX prefix
                          PARAMETERS par1 par2 ...
                          [OPTIONAL_PARAMETERS optPar1 optPar2 ...]
                          [EXCLUSIVE_FLAGS flag1 flag2 ...])

    **Аргументы**

    -              ``PREFIX`` - Префикс парсинга параметров исследуемой функции
    -          ``PARAMETERS`` - Список обязательных параметров
    - ``OPTIONAL_PARAMETERS`` - (опционально) Список опциональных параметров
    -     ``EXCLUSIVE_FLAGS`` - (опционально) Список взаимно исключающих флагов
#]====]

function(__checkParameters__)

    # Если это старт функции
    if(NOT DEFINED __SELF_CHECKING__)

        # Отметить начало этапа самопроверки
        set(__SELF_CHECKING__ True)

        # Задать префикс парсинга
        set(__PARSING_PREFIX__ "__FUNCTION_PARAMETERS_CHECKING__")

        # Парсить аргументы функции (для всех проверок одного раза достаточно)
        cmake_parse_arguments("${__PARSING_PREFIX__}" "" "PREFIX" "PARAMETERS;OPTIONAL_PARAMETERS;EXCLUSIVE_FLAGS" "${ARGN}")

        # Запустить самопроверку (одноуровневая рекурсия)
        __checkParameters__()

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
