OBJS = netCDF_driver.o ncwrapper.o
CC = h4cc
DEBUG = -g
NETCDF_FLAGS = -lm -lnetcdf
LIBRARY_FILES = -Idriver_library
CFLAGS = -Wall $(DEBUG)

program : $(OBJS)
	$(CC) $(DEBUG) $(NETCDF_FLAGS) $(LIBRARY_FILES) $(OBJS) -o program
clean:
	rm -f *.o *~ program


# NAME := driver
# CC = h4cc
# C_SRCS := $(wildcard *.c)
# C_OBJS := ${C_SRCS:.c=.o}
# OBJS := $(C_OBJS)
# INCLUDE_DIRS := ./driver_library
# LIBRARY_DIRS :=
# LIBRARIES :=

# LDFLAGS += $(foreach librarydir,$(LIBRARY_DIRS),-L$(librarydir))
# LDFLAGS += $(foreach library,$(LIBRARIES),-l$(library))

# .PHONY: all clean distclean

# all: $(NAME)

# $(NAME): $(OBJS)
# 	$(CC) $(OBJS) $(LDFLAGS) -o $(NAME)

# clean:
# 	@- $(RM) $(NAME)
# 	@- $(RM) $(OBJS)

# distclean: clean
