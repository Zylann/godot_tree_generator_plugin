#ifndef TG_MACROS_H
#define TG_MACROS_H

#include <Defs.hpp>

// TODO godot-cpp CRASH_COND does not stop execution
// https://github.com/godotengine/godot-cpp/issues/521
#define TG_CRASH_COND(cond)                  \
	do {                                     \
		if (unlikely(cond)) {                \
			FATAL_PRINT(ERR_MSG_COND(cond)); \
			GENERATE_TRAP;                   \
		}                                    \
	} while (0)

#endif // TG_MACROS_H
