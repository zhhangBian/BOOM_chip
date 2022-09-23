include config-software.mak 

comma=,
empty= 
space=${empty} 
soft_list=$(subst ${comma},${space},${RUN_SOFTWARE}) 

all:link soft_compile

link:
	ln -sf ../../chip/config-generator.mak .

include ../../chip/config-generator.mak 

soft_compile:
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING func..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@for soft in ${soft_list}; \
	do 	\
	make -C ${LAB_HOME}/software/$${soft} script; 	\
	rm -rf ./obj/$${soft}_obj;	\
	mv ${LAB_HOME}/software/$${soft}/obj ./obj/$${soft}_obj;	\
	done 

clean:
	for soft in ${soft_list};	\
	do 	\
	rm -rf ./obj/$${soft}_obj;	\
	done 

clean_all:
	rm -rf obj 
	rm -f config-generator.mak
	rm -f config-software.mak 
	rm -f config.log
