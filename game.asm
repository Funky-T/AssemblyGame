#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Tom Daudelin, 1005041367, daudeli3
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8 (update this as needed)
# -Unit height in pixels: 8 (update this as needed)
# -Display width in pixels: 256 (update this as needed)
# -Display height in pixels: 256 (update this as needed)
# -Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# -Milestone 4
#
# Which approved features have been implementedfor milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Smooth graphics
# 2. Scoring system
# 3. Pick-ups/Power-ups
#
# https://play.library.utoronto.ca/play/5cfc93868d02558db2e035f68228e3b2 <--- VIDEO DEMO
#
#Are you OK with us sharing the video with people outside course staff?
# -yes, and please share this project githublink as well!
#
# Any additional information that the TA needs to know:
# -(write here, if any)
#
#####################################################################

.eqv	BASE_ADDRESS		0x10008000
.eqv	INPUT_ADDRESS		0xffff0000
.eqv	SLEEP_VALUE		42
.eqv	B_GROUND_CLR		0x4B0082
.eqv	SCORE_CLR		0x8BC34A
.eqv	ASTROID_CLR		0x9E9E9E
.eqv	NUKE_CLR 		0x4CAF50
.eqv	HP_UP_CLR		0xFF0000
.eqv	STAR_CLR		0xCDDC39
.eqv	PLAYER_CLR_SHIP		0xffffff
.eqv	PLAYER_CLR_GLASS	0x03A8F4
.eqv	PLAYER_CLR_NICE		0xFF5722
.eqv	HEALTH_CLR		0xff1744

.data		
	
star_indecies:	.word 	0, 0, 0		#array that keeps track of each star position
player_index:	.word	2304		#variable that keeps track of the players position
player_health:	.word	3		#variable that keeps track of the players health
astroid_index:	.word	0, 0, 0		#array that keeps track of each astroids position
stack_pointer:	.word 	0		#varaible that keeps track of the original stack pointer in case of reset in nested function call
power_up_index:	.word	0		#variable that keeps track of the position of power ups
player_points:	.word	0		#final variable that resets the player score to default value of zero
	
	
	
.text
.globl main


main:		la $s0, stack_pointer
		lw $sp, 0($s0)		#store stack pointer for resets
		lw $s0, player_health	#$s0 = the players health
		li $s1, INPUT_ADDRESS	#$s1 = address of the user keyboard input
		lw $s2, player_points	#$s2 = player score
		jal draw_background	#draws the purple space background
		jal draw_player		#draws the player
		jal draw_health		#draw the players health
		
main_loop:	
		lw $s0, player_health	#$s0 = the players health
		ble $s0, $zero game_over_screen	#exit loop if health == 0
	
		jal draw_stars		#draws + updates stars
		jal draw_player		#re-draws player over the stars
		jal draw_power_up	#draws power up above the player
		jal draw_astroids	#draw + update the astroids over the player
		jal draw_health		#draw health over the astroids
		jal check_collision	#check for collision
		lw $s0, player_health	#update $s0 (player_health)
		
		lw $s3, 0($s1)		#checks for user input
		bne $s3, 1, main_wait 	#if user input == 0 there is no 
		jal update_player
												
main_wait:	
		jal draw_health		#update player health
		
		#wait 42 milliseconds
		li $v0, 32
		li $a0, 42   # Wait 42 milliseconds 
		syscall
		
																																		
		j main_loop		#loop back to main_loop		
			

#DRAW BACKGROUND
draw_background:	li $t0, BASE_ADDRESS		# $t0 stores the base address for display
			li $t1, B_GROUND_CLR		#$t1 stores the background color
			li $t2, 0			#$t2 = i; where i will iterate
dbf_loop:		beq $t2, 4096, function_exit	#loops over all units (32 by 32 of size 4: 32 * 32 * 4
			add $t3, $t0, $t2		#$t3 = address of the unit to color
			sw $t1, 0($t3)			#colors the unit
			addi $t2, $t2, 4		#adds 4 to the iterator i in order to access the next unit
			j dbf_loop

#DRAW STARS
draw_stars:		li $t0, BASE_ADDRESS	#$t0 = first pixel
			li $t1, 0		#$ti = star array index
			li $t9, STAR_CLR	#$t9 = star color
			li $t7, B_GROUND_CLR	#$t7 = background color
			la $t2, star_indecies	#$t2 = ADDRESS of star_index[0]
for_star:		
			add $t8, $t2, $t1	#$t8 = ADDRESS OF star_index[i]
			
			lw $t4, 0($t8)		#$t4 = the index of the unit containing the star
			sll $t4, $t4, 2		#multiply the index by 4 (unit size)
			add $t4, $t4, $t0	#add to address of first unit to access the current stars unit
			sw $t7, 0($t4)		#deletes star
			
			lw $t3, 0($t8)		#$t3 = star_index[i] which equals the index of where star at i is drawn
	
			#check if star needs to be regenerated
			div $t4, $t3, 32	#divides the the index of star by 4
			mfhi $t4		
			beq $t4, $zero, new_star	#check to see if star was in the first column

			#redraws star at its new correct unit index			
update_star:		
			sub $t3, $t3, 1		#reduces star index by one (gives illusion of star moving to the left)
			sw $t3, 0($t8)		#stores stars new index in the 
			mul $t3, $t3, 4		#multiply index by unit size
			add $t3, $t3, $t0	#add to address of first unit in order to access the correct unit
			sw $t9, 0($t3)		#create star at that index
			
			#update star index
update_star_index:	addi $t1, $t1, 4	#add 4 to the index (to replicate i = i + 1)
			bne $t1, 12, for_star	#iterate 3 times for all three stars
			jr $ra 			#if we have iterated 3 times already exit function

			#Generate a new star randomly around 1/5 chance in theory			
new_star:		li $v0, 42		
			li $a0, 0	
			li $a1, 5		#random number between 0-4
			syscall
			
			bne $a0, 4, update_star_index	
			
			#create new star if random 1/5 chance event happens
			#generate a random row to build star on
draw_new_star:		li $v0, 42
			li $a0, 0
			li $a1, 32
			syscall
			
			#given the random row to build star get index by multiplying by number of units per row, adding number of units per row and subtracting 1
			add $t3, $zero, $a0
			mul $t3, $t3, 32
			addi $t3, $t3, 32
			j update_star	#given the correct unit index + 1 go to update_star section that subtracts this value by 1 and draws the star in the correct place
			
			
			
		
#DRAW PLAYER			
			#set up unit index and player index 
draw_player:		li $t0, BASE_ADDRESS
			lw $t1, player_index
			#load all player colors
			li $t2, PLAYER_CLR_SHIP
			li $t3,	PLAYER_CLR_GLASS
			li $t4, PLAYER_CLR_NICE
			#calculate the players first unit (1st row)
			add $t1, $t1, $t0
			#color in player in the correct units
			sw $t2, 0($t1)
			#calculate the players 2nd row of units
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			sw $t4, 4($t1)
			sw $t3, 8($t1)
			sw $t3, 12($t1)
			#calculate the players 3rd row of units
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			sw $t2, 4($t1)
			sw $t2, 8($t1)
			sw $t2, 12($t1)
			sw $t2, 16($t1)			
			j function_exit

#DELETE PLAYER			
			#set up unit index and player index
delete_player:		li $t0, BASE_ADDRESS
			lw $t1, player_index
			#load background color
			li $t2, B_GROUND_CLR
			#calculate the players first unit (1st row)
			add $t1, $t1, $t0
			#color in player in the correct units
			sw $t2, 0($t1)
			#calculate the players 2nd row of units
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			sw $t2, 4($t1)
			sw $t2, 8($t1)
			sw $t2, 12($t1)
			#calculate the players 3rd row of units
			addi $t1, $t1, 128
			sw $t2, 0($t1)
			sw $t2, 4($t1)
			sw $t2, 8($t1)
			sw $t2, 12($t1)
			sw $t2, 16($t1)			
			j function_exit	

#MOVE PLAYER BASED ON USER INPUT: ASSUMES THAT PLAYER INPUT HAS BEEN GIVEN
update_player:		li $t0, BASE_ADDRESS	#set up unit index and player index 
			lw $t1, player_index	#set up unit index and player index 
			lw $t2, 4($s1)			#get key press
			beq $t2, 0x61, left_key		#check  key
			beq $t2, 0x77, up_key		#check  key
			beq $t2, 0x73, down_key		#check  key
			beq $t2, 0x64, right_key	#check  key
			beq $t2, 0x70, p_key		#check key
			j update_player_end		#exit function if key is not valid
			
valid_key:		sw $ra, -4($sp)			#prepare for nested function call
			addi $sp, $sp, -4		#update stack pointer
			jal delete_player		#delete the player model (at old index)
			la $t1, player_index		#load address of player index
			sw $t3, 0($t1)			#update player index
			jal check_collision		#check colision when running into objects
			jal draw_player			#draw player at new index (giving illusion of movement)
			lw $ra, 0($sp)			#pop return address out of the stack
			addi $sp, $sp, 4		#update the stack pointer
			
update_player_end:	jr $ra				#exit function

up_key:			blt $t1, 128, update_player_end	#exit function if player is in the 1st row	
			addi $t3, $t1, -128		#update the player index (moves it one unit up)
			j valid_key
			
down_key:		bge $t1, 3712, update_player_end	#exit function if player is on last row
			addi $t3, $t1, 128			#update the player index (moves one unit down)
			j valid_key
			
left_key:		div $t4, $t1, 128		#exit function if player on 1st column
			mfhi $t4			
			beq $t4, 0, update_player_end
			addi $t3, $t1, -4		#update player index (moves one unit left)
			j valid_key
			
right_key:		div $t4, $t1, 128		#exit function if player is on the last row
			mfhi $t4
			beq $t4, 108, update_player_end
			addi $t3, $t1, 4		#update player index (moves one unit right)
			j valid_key
			
p_key:			j reset				#reset game
			
function_exit:	jr $ra

#DAMAGE PLAYER ANIMATION (blinking)
damage_player:	sw $ra -4($sp)		#prepare for nested function call
		addi $sp, $sp, -4	#update stack pointer
		
		li $v0, 32
		li $a0, 100   # Wait one tenth of a second (100 milliseconds)
		syscall
		
		lw $s3, 0($s1)		#CHECK FOR USER INPUT
		bne $s3, 1, blink_1	
		jal update_player_damage	#move player if input detected
		
blink_1:	jal delete_player	#make player invisible
		
		li $v0, 32
		li $a0, 100   # Wait one tenth of a second (100 milliseconds)
		syscall
		
		jal draw_player		#make player reappear
		
		lw $s3, 0($s1)		#CHECK FOR USER INPUT
		bne $s3, 1, appear_1
		jal update_player_damage	#move player if input detected
		
appear_1:	li $v0, 32
		li $a0, 100   # Wait one tenth of a second (100 milliseconds)
		syscall

		lw $s3, 0($s1)		#CHECK FOR USER INPUT
		bne $s3, 1, blink_2
		jal update_player_damage	#move player if input detected
						
blink_2:	jal delete_player	#make player invisible
		
		li $v0, 32
		li $a0, 100   # Wait one tenth of a second (100 milliseconds)
		syscall
		
		jal draw_player		#make player reappear
		
		lw $s3, 0($s1)		#CHECK FOR USER INPUT
		bne $s3, 1, appear_2
		jal update_player_damage	#move player if input detected
		
appear_2:	li $v0, 32
		li $a0, 100   # Wait one second (1000 milliseconds)
		syscall
		
		lw $s3, 0($s1)		#CHECK FOR USER INPUT
		bne $s3, 1, blink_3
		jal update_player_damage	#move player if input detected
		
blink_3:	jal delete_player	#make player invisible
		
		li $v0, 32
		li $a0, 100   # Wait one second (1000 milliseconds)
		syscall
		
		jal draw_player		#make player reappear
		
		lw $ra 0($sp)		#pop return address out of stack
		addi $sp, $sp, 4	#update stack pointer
		
		lw $t3, player_health
		ble $t3, 0, main_loop	#check to see if player is dead
						
		jr $ra			#exit function
		

#DRAWS PLAYER HEALTH
draw_health:	li $t0, BASE_ADDRESS	#loads address of first unit
		lw $t9, player_health	#loads player health variable
		
		
		li $t3, HEALTH_CLR	#heart 3 = heart
		li $t2, HEALTH_CLR	#heart 2 = heart
		li $t1, HEALTH_CLR	#heart 1 = heart
		beq $t9, 3, clr_hearts	#if player health equals 3 color hearts
		li $t3, B_GROUND_CLR	#else heart 3 = no heart
		beq $t9, 2, clr_hearts	#if player health equals 2 color hearts
		li $t2, B_GROUND_CLR	#else heart 2 = no heart
		beq $t9, 1, clr_hearts	#if player health equals 1 color hearts
		li $t1, B_GROUND_CLR	#else heart 1 = no hearts
		
clr_hearts:	sw $t1, 4($t0)		#color heart 1
		sw $t2, 12($t0)		#color heart 2
		sw $t3, 20($t0)		#color heart 3
		
		jr $ra			#exit function
		
draw_astroids:	sw $ra -4($sp)
		addi $sp, $sp, -4
		
		li $t0, BASE_ADDRESS	#$t0 = first pixel
		li $t1, ASTROID_CLR	#$t1 = astroid color
		li $t7, B_GROUND_CLR	#$t7 = background color
		la $t2, astroid_index	#$t2 = ADDRESS of astroid_index[0]
		li $t3, 0		#$t3 = i
		
for_astroid:	add $t8, $t2, $t3	#$t8 = ADDRESS OF star_index[i]
		lw $t5, 0($t8)		#$t5 = star_index[i] which equals the index of where star at i is drawn
		
		
		#check to see if astroid is non existant or if astroid is at the edge
		div $t4, $t5, 32
		mfhi $t4
		beq $t4, $zero, new_astroid
		
		
update_astroid:	mul $t9, $t5, 4		#$t9 = the the unit index times size of unit
		add $t9, $t9, $t0	#$t9 = the address of the astroids unit
		add $t6, $zero, $t7	#$t6 = background color
		
		#delete last unit of each row of the astroids unit
		sw $t6, 12($t9)
		sw $t6, 144($t9)
		sw $t6, 272($t9)
		sw $t6, 400($t9)
		sw $t6, 524($t9)
		
		#update astroid index
		sub $t5, $t5, 1
		#store unit index
		sw $t5, 0($t8)
		
		mul $t9, $t5, 4		#$t9 = the the unit index times size of unit
		add $t9, $t9, $t0	#$t9 = the address of the astroids unit
		add $t6, $zero, $t1	#$t6 = astroid color
		
		#adds astroid color to first unit of each row of the astroids unit
		sw $t6, 4($t9)
		sw $t6, 128($t9)
		sw $t6, 256($t9)
		sw $t6, 384($t9)
		sw $t6, 516($t9)
		
update_astroid_index:
		addi $t3, $t3, 4		#i = i + 1 (since size of unit = 4)
		bne $t3, 12, for_astroid	#if iterated 3 times then exit function
		lw $ra, 0($sp)			#pop return address out of stack
		add $sp, $sp, 4			#update return address
		jr $ra 				#exit function
		
		
		
new_astroid:	add $t6, $zero, $t7	#SET ASTROID COLOR TO BACKGROUND COLOR IN ORDER TO DELETE ASTROID since new astroids mean that an old one must be deleted
		jal clr_astroid		#delete old astroid

		#randomly generate a new astroid 1/5 of the time
		li $v0, 42
		li $a0, 0
		li $a1, 5
		syscall			
			
		bne $a0, 4, update_astroid_index
		
		addi, $s2, $s2, 50	#gives the player 50 points for every astroid spawned
		
		#generates an astroid at a random height
		li $v0, 42
		li $a0, 0
		li $a1, 28
		syscall
		
		#parses row number to specific starting index for the astroid
		add $t5, $zero, $a0	
		mul $t5, $t5, 32
		addi $t5, $t5, 28
		
		sub $t5, $t5, 1
		sw $t5, 0($t8)		#update astroid index to store the new astroids position
		add $t6, $zero, $t1	#sets color to astroid color
		jal clr_astroid		#draw the complete astroid at the correct height
		j update_astroid_index	#update the astroid
		
		#completely colors an astroid with color stored in $t6 (can be used to spawn a new astroid or completely delete an old one)
		#$t5 = index of astroid
clr_astroid:	mul $t9, $t5, 4
		add $t9, $t9, $t0
		sw $t6, 4($t9)
		sw $t6, 8($t9)
		sw $t6, 12($t9)
		
		sw $t6, 128($t9)
		sw $t6, 132($t9)
		sw $t6, 136($t9)
		sw $t6, 140($t9)
		sw $t6, 144($t9)
		
		sw $t6, 256($t9)
		sw $t6, 260($t9)
		sw $t6, 264($t9)
		sw $t6, 268($t9)
		sw $t6, 272($t9)
		
		sw $t6, 384($t9)
		sw $t6, 388($t9)
		sw $t6, 392($t9)
		sw $t6, 396($t9)
		sw $t6, 400($t9)
		
		sw $t6, 516($t9)
		sw $t6, 520($t9)
		sw $t6, 524($t9)
		
		jr $ra
save_data_collision:
			sw $t0, -4($sp)
			sw $t1, -8($sp)
			sw $t2, -12($sp)
			sw $t3, -16($sp)
			sw $t4, -20($sp)
			sw $t5, -24($sp)
			addi $sp, $sp, -24
			jr $ra
			
load_data_collision:	lw $t5, 0($sp)
			lw $t4, 4($sp)
			lw $t3, 8($sp)
			lw $t2, 12($sp)
			lw $t1, 16($sp)
			lw $t0,	20($sp)
			addi $sp, $sp, 24
			jr $ra
				
		#Checks for collisions at all the edges of the player model by checking if astroid color covers player model
check_collision:	li $t0, BASE_ADDRESS	#loads address of first unit
			lw $t1, player_index	#loads unit index of the player
			li $t3, ASTROID_CLR	#loasd colo
			li $t4, NUKE_CLR
			li $t5, HP_UP_CLR
			
			sw $ra, -4($sp)
			addi $sp, $sp, -4
			
			add $t1, $t1, $t0	#gets the addres of the players unit
			lw $t2, 0($t1)		#CHECK HIT
			beq $t2, $t3, found_collision	#found colision if we find astroids color
			bne $t2, $t4, check_next_1
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_1:		bne $t2, $t5, check_next_2
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
check_next_2:		addi $t1, $t1, 128	#checks on 2nd row of player model
			lw $t2, 12($t1)		#CHECK HIT
			beq $t2, $t3, found_collision	#found colision if we find astroids color
			bne $t2, $t4, check_next_3
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_3:		bne $t2, $t5, check_next_4
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
check_next_4:		addi $t1, $t1, 128	#checks on 3rd row of player
			lw $t2, 0($t1)		#CHECK HIT
			beq $t2, $t3, found_collision	#found colision if we find astroids color
			bne $t2, $t4, check_next_5
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_5:		bne $t2, $t5, check_next_6
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
check_next_6:		lw $t2, 4($t1)		#CHECK HIT
			bne $t2, $t4, check_next_7
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_7:		bne $t2, $t5, check_next_8
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
			
check_next_8:		lw $t2, 8($t1)		#CHECK HIT
			beq $t2, $t3, found_collision	#found colision if we find astroids color
			bne $t2, $t4, check_next_9
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_9:		bne $t2, $t5, check_next_10
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
			
check_next_10:		lw $t2, 12($t1)		#CHECK HIT
			bne $t2, $t4, check_next_11
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_11:		bne $t2, $t5, check_next_12
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
			
check_next_12:		lw $t2, 16($t1)		#CHECK HIT
			beq $t2, $t3, found_collision	#found colision if we find astroids color	
			bne $t2, $t4, check_next_13
			jal save_data_collision
			jal nuke
			jal load_data_collision
check_next_13:		bne $t2, $t5, check_end
			jal save_data_collision
			jal health_up
			jal load_data_collision
			
check_end:		lw $ra, 0($sp)
			addi $sp, $sp, 4		
			j function_exit
			
			
found_collision:	sw $ra, -4($sp)		#store return address in stack to prepare for a nested function call
			add $sp, $sp, -4	#updates stack pointer
			
			la $t2, player_health	#load address of player health
			lw $t3, 0($t2)		#load player health
			add $t3, $t3, -1	#remove one health from player
			sw $t3, 0($t2)		#store new health back into the player health variable
			jal draw_health		#redraw health to reflect health changes
			ble $t3, 0, main_loop	#check if player is dead
			jal damage_player	#call the damage player function for animation
			
			lw $ra, 0($sp)		#pop return address out of stack
			add $sp, $sp, 4		#updates stack pointer
			
			j function_exit

health_up:		addi $s2, $s2, 1000		#gives player 1000 points
			lw $t0, player_health		#load player health
			beq $t0, 3, health_up_end	#check if is at max health, if yes then exit
			addi $t0, $t0, 1		#if not, add 1 to player health
			sw $t0, player_health
			sw $ra, -4($sp)			#push return address to stack
			addi $sp, $sp, -4		#update stack pointer
			jal draw_health			#update health on screen
			lw $ra, 0($sp)			#pop return address out of stack
			add $sp, $sp, 4			#update stack pointer
health_up_end:		
			li $t7, B_GROUND_CLR
			li $t8, BASE_ADDRESS
			lw $t9, power_up_index
			
			sll $t9, $t9, 2
			add $t9, $t9, $t8
			sw $t1, 0($t9)
			sw $zero, power_up_index
			jr $ra

nuke:			addi $s2, $s2, 100	#gives player 100 points
			sw $ra -4($sp)		#prepares for nested function call
			addi $sp, $sp, -4	#updates stack pointer
		
			li $t0, BASE_ADDRESS	#$t0 = first pixel
			li $t1, B_GROUND_CLR	#$t1 = background color
			la $t2, astroid_index	#$t2 = ADDRESS of astroid_index[0]
			add $t6, $zero, $t1	#SET ASTROID COLOR TO BACKGROUND COLOR IN ORDER TO DELETE ASTROID since new astroids mean that an old one must be deleted
			li $t3, 0		#$t3 = i
		
nuke_astroid:		add $t8, $t2, $t3	#$t8 = ADDRESS OF star_index[i]
			lw $t5, 0($t8)		#$t5 = the index at which the astroid is drawn
			jal clr_astroid		#delete astroid
			sw $zero, 0($t8)	#update the astroid index to 0
			
			#update iterator
			addi $t3, $t3, 4
			bne $t3, 12, nuke_astroid	#check to see if there are astroids left to delete
			lw $ra 0($sp)			#pop return address out of stack
			addi $sp, $sp, 4		#update stack pointer
			
			li $v0, 32
			li $a0, 1000   # Wait 1000 milliseconds 
			syscall
			
			lw $t9, power_up_index
			sll $t9, $t9, 2
			add $t9, $t9, $t0
			sw $t1, 0($t9)
			sw $zero, power_up_index
			
			jr $ra				#exit function
			


game_over_screen:	jal draw_background
			li $t0, BASE_ADDRESS
			li $t1, STAR_CLR
			li $t2, SCORE_CLR
			li $t3, PLAYER_CLR_NICE
			
			#draw the letter G
			sw $t1, 908($t0)
			sw $t1, 912($t0)
			sw $t1, 916($t0)
			sw $t1, 1032($t0)	#2nd row of G
			sw $t1, 1160($t0)	#3rd row of G
			sw $t1, 1172($t0)
			sw $t1, 1176($t0)
			sw $t1, 1288($t0)	#4th row of G
			sw $t1, 1304($t0)
			sw $t1, 1420($t0)	#5th row of G
			sw $t1, 1424($t0)
			sw $t1, 1428($t0)
			
			#draw letter A
			sw $t1, 936($t0)
			sw $t1, 1060($t0)	#2nd row of A
			sw $t1, 1068($t0)
			sw $t1, 1184($t0)	#3rd row of A
			sw $t1, 1200($t0)
			sw $t1, 1312($t0)	#4th row of A
			sw $t1, 1316($t0)
			sw $t1, 1320($t0)
			sw $t1, 1324($t0)
			sw $t1, 1328($t0)
			sw $t1, 1440($t0)	#5th row of A
			sw $t1, 1456($t0)
			
			#draw letter m
			sw $t1, 1084($t0)
			sw $t1, 1092($t0)
			sw $t1, 1208($t0)	#2nd row of m
			sw $t1, 1216($t0)
			sw $t1, 1224($t0)
			sw $t1, 1336($t0)	#3rd row of m
			sw $t1, 1344($t0)
			sw $t1, 1352($t0)
			sw $t1, 1464($t0)	#4rth row of m
			sw $t1, 1472($t0)
			sw $t1, 1480($t0)
			
			#draw letter E
			sw $t1, 976($t0)
			sw $t1, 980($t0)
			sw $t1, 984($t0)
			sw $t1, 1104($t0)	#2nd row of E
			sw $t1, 1232($t0)	#3rd row of E																																																						
			sw $t1, 1236($t0)																																																																																																												
			sw $t1, 1240($t0)
			sw $t1, 1360($t0)	#4th row of E
			sw $t1, 1488($t0)	#5th row of E
			sw $t1, 1492($t0)
			sw $t1, 1496($t0)
			
			#draw letter O
			sw $t1, 1800($t0)																																																																																																																																																																																																																																																																																																																																				
			sw $t1, 1804($t0)
			sw $t1, 1808($t0)
			sw $t1, 1812($t0)
			sw $t1, 1816($t0)
			
			sw $t1, 1928($t0)	#2nd row of O
			sw $t1, 1944($t0)
			sw $t1, 2056($t0)	#3rd row of O
			sw $t1, 2072($t0)
			sw $t1, 2184($t0)	#4th row of O
			sw $t1, 2200($t0)
			sw $t1, 2312($t0)	#5th row of O
			sw $t1, 2316($t0)
			sw $t1, 2320($t0)
			sw $t1, 2324($t0)
			sw $t1, 2328($t0)
			
			#draw letter v
			sw $t1, 2080($t0)
			sw $t1, 2096($t0)
			sw $t1, 2212($t0)	#2nd row of v
			sw $t1, 2220($t0)
			sw $t1, 2344($t0)	#3rd row of v
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
			#draw letter E
			sw $t1, 1848($t0)	
			sw $t1, 1852($t0)
			sw $t1, 1856($t0)
			sw $t1, 1976($t0)	#2nd row of E
			sw $t1, 2104($t0)	#3rd row of E
			sw $t1, 2108($t0)
			sw $t1, 2112($t0)
			sw $t1, 2232($t0)	#4th row of E
			sw $t1, 2360($t0)	#5th row of E
			sw $t1, 2364($t0)
			sw $t1, 2368($t0)
			
			#draw letter R
			sw $t1, 1864($t0)
			sw $t1, 1868($t0)
			sw $t1, 1872($t0)
			sw $t1, 1876($t0)
			sw $t1, 1992($t0)	#2nd row of R
			sw $t1, 2004($t0)
			sw $t1, 2120($t0)	#3rd row of R
			sw $t1, 2124($t0)
			sw $t1, 2128($t0)
			sw $t1, 2132($t0)
			sw $t1, 2248($t0)	#4th row of R
			sw $t1, 2256($t0)
			sw $t1, 2376($t0)	#5th row of R
			sw $t1, 2388($t0)
			
			#draw "SCORE:"
			#draw letter S
			sw $t2, 2564($t0)
			sw $t2, 2568($t0)
			sw $t2, 2572($t0)
			sw $t2, 2692($t0)	#2nd row of S
			sw $t2, 2820($t0)	#3rd row of S
			sw $t2, 2824($t0)
			sw $t2, 2828($t0)
			sw $t2, 2956($t0)	#4th row of S
			sw $t2, 3076($t0)	#5th row of S
			sw $t2, 3080($t0)
			sw $t2, 3084($t0)
			
			#draw letter C
			sw $t2, 2580($t0)
			sw $t2, 2584($t0)
			sw $t2, 2588($t0)
			sw $t2, 2708($t0)	#2nd row of C
			sw $t2, 2836($t0)	#3rd row of C
			sw $t2, 2964($t0)	#4th row of C
			sw $t2, 3092($t0)	#5th row of C
			sw $t2, 3096($t0)
			sw $t2, 3100($t0)
			
			#draw letter O
			sw $t2, 2596($t0)
			sw $t2, 2600($t0)
			sw $t2, 2604($t0)
			sw $t2, 2724($t0)	#2nd row of O
			sw $t2, 2732($t0)
			sw $t2, 2852($t0)	#3rd row of O
			sw $t2, 2860($t0)
			sw $t2, 2980($t0)	#4th row of O
			sw $t2, 2988($t0)
			sw $t2, 3108($t0)	#5th row of O
			sw $t2, 3112($t0)
			sw $t2, 3116($t0)
			
			#draw letter R
			sw $t2, 2612($t0)
			sw $t2, 2616($t0)
			sw $t2, 2620($t0)
			sw $t2, 2740($t0)	#2nd row of R
			sw $t2, 2748($t0)
			sw $t2, 2868($t0)	#3rd row of R
			sw $t2, 2872($t0)
			sw $t2, 2876($t0)
			sw $t2, 2996($t0)	#4th row of R
			sw $t2, 3000($t0)				
			sw $t2, 3124($t0)	#5th row of R
			sw $t2, 3132($t0)
			
			#draw letter E
			sw $t2, 2628($t0)
			sw $t2, 2632($t0)
			sw $t2, 2636($t0)
			sw $t2, 2756($t0)	#2nd row of R
			sw $t2, 2884($t0)	#3rd row of R
			sw $t2, 2888($t0)
			sw $t2, 2892($t0)
			sw $t2, 3012($t0)	#4th row of R
			sw $t2, 3140($t0)	#5th row of R
			sw $t2, 3144($t0)
			sw $t2, 3148($t0)
			
			#draw ":"
			sw $t2, 2772($t0)
			sw $t2, 3028($t0)
			
drawing_score:		addi $t9, $t0, 3332 	#$t9 = index of row to write score on (row 27)
			addi $t8, $zero, 10000000
			addi $t5, $zero, 10
draw_score_loop:	j parse_score

post_parse_score:	addi $t9, $t9, 16	#update index to draw number
			mul $t6, $t8, $t7	#multiply power of 10 by number of times it appears in score
			sub $s2, $s2, $t6	#subtract most significant digit off of the score
			div $t8, $t8, $t5		#divide power of 10 by 10 to go to the next most significant digits
			bne $t8, 0, draw_score_loop	
			j reset_loop
			
			
parse_score:	div $s2, $t8	
		mflo $t7
is_zero:	bne $t7, 0, is_one	
		j draw_zero
is_one:		bne $t7, 1, is_two
		j draw_one
is_two:		bne $t7, 2, is_three
		j draw_two
is_three:	bne $t7, 3, is_four
		j draw_three
is_four:	bne $t7, 4, is_five
		j draw_four
is_five:	bne $t7, 5, is_six
		j draw_five
is_six:		bne $t7, 6, is_seven
		j draw_six
is_seven:	bne $t7, 7, is_eight
		j draw_seven
is_eight:	bne $t7, 8, is_nine
		j draw_eight
is_nine:	j draw_nine
			

		
									
reset_loop:		lw $s5, 0($s1)		#checks for user input
			bne $s5, 1, reset_loop
			lw $t2, 4($s1)			#get key press	
			beq $t2, 0x70, p_key		#check key
			j reset_loop

draw_power_up:		li $t0, BASE_ADDRESS	#$t0 = first pixel
			li $t1, HP_UP_CLR	#$t1 = color of health up power up 
			li $t2,	NUKE_CLR	#$t2 = color of nuke power up
			li $t7, B_GROUND_CLR	#$t7 = background color
			lw $t3, power_up_index	#$t3 = the index where power up is drawn
			
			mul $t8, $t3, 4
			add $t8, $t8, $t0	#$t8 = the address of the unit where power up is drawn
			lw $t4, 0($t8)		#stores power up color
				
			sw $t7, 0($t8)		#delete old power up
			
			#check if power up needs to be regenerated
			div $t6, $t3, 32		#divides the the index of star by 4
			mfhi $t6			
			beq $t6, $zero, new_power_up
			sub $t3, $t3, 1
			sw $t3, power_up_index
update_power_up:	mul $t8, $t3, 4
			add $t8, $t8, $t0
			sw $t4, 0($t8)
	
			jr $ra
			
			
new_power_up:		#Generate a new power up randomly around 1/50 chance in theory			
			li $v0, 42		
			li $a0, 0	
			li $a1, 50		#random number between 0-49
			syscall
			
			bne $a0, 4, function_exit
			
			add $t4, $zero, $t1 	#set power up to be generated to be a health power up
			
			li $v0, 42		
			li $a0, 0	
			li $a1, 2		#random number between 0-1
			syscall
			
			beq $a0, 0, new_power_up_index
			add $t4, $zero, $t2	#sets power up to be a nuke randomly 1/2 chance
			
			#choose new row to spawn star
new_power_up_index:	li $v0, 42		
			li $a0, 0	
			li $a1, 32		#random number between 0-31
			syscall
			
			#given the random row to build star get index by multiplying by number of units per row, adding number of units per row and subtracting 1
			add $t3, $zero, $a0
			mul $t3, $t3, 32
			addi $t3, $t3, 31
			sw $t3, power_up_index
			j update_power_up	#given the correct unit index + 1 go to update_star section that subtracts this value by 1 and draws the star in the correct place

						


update_player_damage:	li $t0, BASE_ADDRESS	#set up unit index and player index 
			lw $t1, player_index	#set up unit index and player index 
			lw $t2, 4($s1)			#get key press
			beq $t2, 0x61, left_key_damage	#check  key
			beq $t2, 0x77, up_key_damage	#check  key
			beq $t2, 0x73, down_key_damage	#check  key
			beq $t2, 0x64, right_key_damage	#check  key
			beq $t2, 0x70, p_key		#check key
			j update_player_end		#exit function if key is not valid
			
valid_key_damage:	sw $ra, -4($sp)			#prepare for nested function call
			addi $sp, $sp, -4		#update stack pointer
			jal delete_player		#delete the player model (at old index)
			la $t1, player_index		#load address of player index
			sw $t3, 0($t1)			#update player index
			#jal check_collision_damage	#check colision when running into objects
			jal draw_player			#draw player at new index (giving illusion of movement)
			lw $ra, 0($sp)			#pop return address out of the stack
			addi $sp, $sp, 4		#update the stack pointer
			jr $ra

up_key_damage:		blt $t1, 128, update_player_end	#exit function if player is in the 1st row	
			addi $t3, $t1, -128		#update the player index (moves it one unit up)
			j valid_key_damage
			
down_key_damage:	bge $t1, 3712, update_player_end	#exit function if player is on last row
			addi $t3, $t1, 128			#update the player index (moves one unit down)
			j valid_key_damage
			
left_key_damage:	div $t4, $t1, 128		#exit function if player on 1st column
			mfhi $t4			
			beq $t4, 0, update_player_end
			addi $t3, $t1, -4		#update player index (moves one unit left)
			j valid_key_damage
			
right_key_damage:	div $t4, $t1, 128		#exit function if player is on the last row
			mfhi $t4
			beq $t4, 108, update_player_end
			addi $t3, $t1, 4		#update player index (moves one unit right)
			j valid_key_damage



draw_zero:	#$t9 = start index
		sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 0
		sw $t3, 136($t9)
		sw $t3, 256($t9)		#3rd row of 0
		sw $t3, 264($t9)
		sw $t3, 384($t9)		#4th row of 0
		sw $t3, 392($t9)
		sw $t3, 512($t9)		#5th row of 0
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score
		
		
draw_one:	sw $t3, 4($t9)
		sw $t3, 128($t9)		#2nd row of 1
		sw $t3, 132($t9)
		sw $t3, 256($t9)		#3rd row of 1
		sw $t3, 260($t9)
		sw $t3, 388($t9)		#4th row of 1
		sw $t3, 516($t9)		#5th row of 1
		j post_parse_score	
		
draw_two:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 136($t9)		#2nd row of 2
		sw $t3, 256($t9)		#3rd row of 2
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 384($t9)		#4th row of 2
		sw $t3, 512($t9)		#5th row of 2
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score	
		
draw_three:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 136($t9)		#2nd row of 3
		sw $t3, 256($t9)		#3rd row of 3
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 392($t9)		#4th row of 3
		sw $t3, 512($t9)		#5th row of 3
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score	
		
draw_four:	sw $t3, 0($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 4
		sw $t3, 136($t9)
		sw $t3, 256($t9)		#3rd row of 4
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 392($t9)		#4th row of 4
		sw $t3, 520($t9)		#5th row of 4
		j post_parse_score
		
draw_five:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 5
		sw $t3, 256($t9)		#3rd row of 5
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 392($t9)		#4th row of 5
		sw $t3, 512($t9)		#5th row of 5
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score
		
draw_six:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 6
		sw $t3, 256($t9)		#3rd row of 6
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 384($t9)		#4th row of 6
		sw $t3, 392($t9)
		sw $t3, 512($t9)		#5th row of 6
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score
		
draw_seven:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 136($t9)		#2nd row of 7
		sw $t3, 260($t9)		#3rd row of 7
		sw $t3, 384($t9)		#4th row of 7
		sw $t3, 512($t9)		#5th row of 7
		j post_parse_score
		
draw_eight:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 8
		sw $t3, 136($t9)
		sw $t3, 256($t9)		#3rd row of 8
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 384($t9)		#4th row of 8
		sw $t3, 392($t9)
		sw $t3, 512($t9)		#5th row of 8
		sw $t3, 516($t9)
		sw $t3, 520($t9)
		j post_parse_score
		
draw_nine:	sw $t3, 0($t9)
		sw $t3, 4($t9)
		sw $t3, 8($t9)
		sw $t3, 128($t9)		#2nd row of 9
		sw $t3, 136($t9)
		sw $t3, 256($t9)		#3rd row of 9
		sw $t3, 260($t9)
		sw $t3, 264($t9)
		sw $t3, 392($t9)		#4th row of 4
		sw $t3, 520($t9)		#5th row of 4
		j post_parse_score
		
reset:		#reset stars
		la $t0 star_indecies
		li $t1, 0
		sw $t1, 0($t0)
		sw $t1, 4($t0)
		sw $t1, 8($t0)
		
		#reset astroids
		la $t0, astroid_index
		sw $t1, 0($t0)
		sw $t1, 4($t0)
		sw $t1, 8($t0)
		
		#reset player index
		la $t0, player_index
		li $t1, 2304
		sw $t1, 0($t0)
		
		#reset player health
		la $t0, player_health
		li $t1, 3
		sw $t1, 0($t0)
		
		#reset stack pointer
		lw $sp, stack_pointer
		
		
		#restart loop
		j main

exit:	li $v0, 10 # terminate the program gracefully
	syscall
