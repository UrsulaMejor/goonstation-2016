/////////////////////////////
//      Deployer Code      //
/////////////////////////////

/obj/item/turret_deployer
	name = "NAS-T"
	desc = "A Nuclear Agent Sentry Turret."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "st_deployer"
	force = 3.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = 4
	health = 100
	var/emagged = 0
	var/damage_words = "fully operational!"

	New()
		..()

	get_desc(dist)
		. = "<br><span style='color: blue'>It looks [damage_words]</span>"


	attackby(obj/item/W, mob/user)
		if(istype(W, /obj/item/weldingtool) && W:welding)
			var/turf/T = user.loc
			if (!istype(src.loc, /turf))
				user.show_message("You can't weld the turret down there!")
				return

			if (W:get_fuel() < 1)
				user.show_message("<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return

			W:use_fuel(1)
			user.show_message("You start to weld the turret to the floor.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(20)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				user.show_message("You weld the turret to the floor.")
				src.spawn_turret(T)
				qdel(src)

			else if((istype(user, /mob/living/silicon/robot) && (user.loc == T)))
				user.show_message("You weld the turret to the floor.")
				src.spawn_turret(T)
				qdel(src)

			return

	proc/spawn_turret(var/turf/user_loc)
		var/direct = get_dir(user_loc,src.loc)
		var/obj/deployable_turret/turret = new /obj/deployable_turret(src.loc,direction=direct)
		turret.health = src.health // NO FREE REPAIRS, ASSHOLES
		turret.emagged = src.emagged
		turret.damage_words = src.damage_words

	emag_act(var/user, var/emag)
		if(src.emagged)
			return
		src.emagged = 1
		boutput(user,"You short out the safeties on the turret.")
		src.damage_words += "<br><span style='color: red'>Its safety indicator is off!</span>"

/////////////////////////////
//       Turret Code       //
/////////////////////////////

/obj/deployable_turret

	name = "NAS-T"
	desc = "A Nuclear Agent Sentry Turret."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "st_off"
	anchored = 1
	density = 1
	var/health = 100
	var/max_health = 100
	var/list/mob/living/target_list = list()
	var/mob/living/target = null
	var/wait_time = 30 //wait if it can't find a target
	var/range = 7 // tiles
	var/internal_angle = 0 // used for the matrix transforms
	var/external_angle = 180 // used for determining target validity
	var/projectile_type = /datum/projectile/bullet/ak47
	var/datum/projectile/current_projectile = new/datum/projectile/bullet/ak47
	var/burst_size = 3 // number of shots to fire. Keep in mind the bullet's shot_count
	var/fire_rate = 3 // rate of fire in shots per second
	var/angle_arc_size = 30
	var/active = 0 // are we gonna shoot some peeps?
	var/emagged = 0
	var/damage_words = "fully operational!"
	var/waiting = 0 // tracks whether or not the turret is waiting
	var/shooting = 0 // tracks whether we're currently in the process of shooting someone

	New(var/direction)
		..()
		src.dir = direction
		src.set_initial_angle()

		src.icon_state = "st_base"
		src.appearance_flags |= PIXEL_SCALE
		src.appearance_flags |= RESET_TRANSFORM
		src.underlays += src
		src.appearance_flags &= ~RESET_TRANSFORM
		src.icon_state = "st_off"
		src.appearance_flags |= PIXEL_SCALE

		var/matrix/M = matrix()
		src.transform = M.Turn(src.external_angle)
		if (!(src in processing_items))
			processing_items.Add(src)




	disposing()
		processing_items.Remove(src)
		..()


	get_desc(dist)
		. = "<br><span style='color: blue'>It looks [damage_words]</span>"

	proc/set_initial_angle()
		switch(src.dir)
			if(NORTH)
				src.external_angle = (0)
			if(NORTHEAST)
				src.external_angle = (45)
			if(EAST)
				src.external_angle = (90)
			if(SOUTHEAST)
				src.external_angle = (135)
			if(SOUTH)
				src.external_angle = (180)
			if(SOUTHWEST)
				src.external_angle = (225)
			if(WEST)
				src.external_angle = (270)
			if(NORTHWEST)
				src.external_angle = (315)
			else
				src.external_angle = (180) // how did you get here?


	proc/process() //main turret processing loop
		if(src.waiting || src.shooting)
			return
		if(src.active)
			if(!src.target)
				if(!src.seek_target())
					src.waiting = 1
					spawn(src.wait_time)
						src.waiting = 0
					return
			if(!src.target_valid(src.target))
				src.icon_state = "st_idle"
				src.target = null
				return
			else
				src.shooting = 1
				src.icon_state = "st_fire"
				spawn()
					for (var/i = 0, i<burst_size, i++)
						if(src.target)
							shoot(src.target.loc,src.loc,src)
							sleep(10/fire_rate)
						else
							src.icon_state = "st_idle"
							src.target = null
							break
					src.shooting = 0
					src.icon_state = "st_active"


	attackby(obj/item/W, mob/user)
		if (istype(W, /obj/item/weldingtool) && W:welding && !(src.active))
			var/turf/T = user.loc
			if (W:get_fuel() < 1)
				user.show_message("<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return

			W:use_fuel(1)
			user.show_message("You start to unweld the turret from the floor.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(30)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				user.show_message("You unweld the turret from the floor.")
				src.active = 0
				src.shooting = 0
				src.waiting = 0
				src.target = null
				src.spawn_deployer()
				qdel(src)

			else if((istype(user, /mob/living/silicon/robot) && (user.loc == T)))
				user.show_message("You unweld the turret from the floor.")
				src.active = 0
				src.shooting = 0
				src.waiting = 0
				src.target = null
				src.spawn_deployer()
				qdel(src)

			return

		if (istype(W, /obj/item/weldingtool) && W:welding && (src.active))
			var/turf/T = user.loc
			if (src.health >= max_health)
				user.show_message("<span style=\"color:blue\">The turret is already fully repaired!.</span>")
				return

			if (W:get_fuel() < 1)
				user.show_message("<span style=\"color:blue\">You need more welding fuel to complete this task.</span>")
				return

			W:use_fuel(1)
			user.show_message("You start to repair the turret.")
			playsound(src.loc, "sound/items/Welder2.ogg", 50, 1)
			sleep(20)

			if ((user.loc == T && user.equipped() == W))
				W:eyecheck(user)
				user.show_message("You repair some of the damage on the turret.")
				src.health = min(src.max_health, (src.health + 10))
				src.check_health()

			return

		else if (istype(W, /obj/item/wrench))
			var/angle = input(usr, "Degrees clockwise from North:", "What would you like to set the angle to?", 0) as num
			if(angle == null)
				return
			playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
			src.set_angle(angle)

		else if (istype(W, /obj/item/card/emag))
			return

		else if (istype(W, /obj/item/screwdriver))

			var/turf/T = user.loc

			playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)

			sleep(10)

			if ((user.loc == T && user.equipped() == W))
				if(src.active)
					user.show_message("<span style=\"color:blue\">You power off the turret.</span>")
					src.icon_state = "st_off"
					src.active = 0
					src.shooting = 0
					src.waiting = 0
					src.target = null

				else
					user.show_message("<span style=\"color:blue\">You power on the turret.</span>")
					src.active = 1
					src.icon_state = "st_idle"

			else if((istype(user, /mob/living/silicon/robot) && (user.loc == T)))
				if(src.active)
					user.show_message("<span style=\"color:blue\">You power off the turret.</span>")
					src.icon_state = "st_off"
					src.active = 0
					src.shooting = 0
					src.waiting = 0
					src.target = null

				else
					user.show_message("<span style=\"color:blue\">You power on the turret.</span>")
					src.active = 1
					src.icon_state = "st_idle"

		else
			src.visible_message("<span style=\"color:red\"><b>[user]</b> bashes [src] with the [W]!</span>")
			src.health = src.health - W.force
			src.check_health()


	bullet_act(var/obj/projectile/P)
		src.health = src.health - P.power
		src.check_health()


	proc/check_health()
		if(src.health <= 0)
			src.active = 0
			src.shooting = 0
			src.waiting = 0
			src.target = null
			src.die()

		var/percent_damage = src.health/src.max_health * 100
		switch(percent_damage)
			if(90 to 100)
				damage_words = "fully operational!"
			if(75 to 89)
				damage_words = "a little bit damaged."
			if(30 to 74)
				damage_words = "looks pretty beaten up."
			if(0 to 29)
				damage_words = "to be on the verge of falling apart!"

		if(src.emagged)
			damage_words += "<br><span style='color: red'>Its safety indicator is off!</span>"


	proc/die()
		playsound(src.loc, "sound/effects/robogib.ogg", 50, 1)
		new /obj/decal/cleanable/robot_debris(src.loc)
		qdel(src)


	proc/spawn_deployer()
		var/obj/item/turret_deployer/deployer = new /obj/item/turret_deployer(src.loc)
		deployer.health = src.health // NO FREE REPAIRS, ASSHOLES
		deployer.emagged = src.emagged
		deployer.damage_words = src.damage_words


	proc/seek_target()
		src.target_list = list()
		for (var/mob/living/C in mobs)
			if(!src)
				break

			if (src.target_valid(C))
				src.target_list += C
				var/distance = get_dist(C.loc,src.loc)
				src.target_list[C] = distance

			else
				continue

		if (src.target_list.len>0)
			var/min_dist = 99999

			for (var/mob/living/T in src.target_list)
				if (src.target_list[T] < min_dist)
					src.target = T
					min_dist = src.target_list[T]

			src.icon_state = "st_active"

			playsound(src.loc, "sound/vox/woofsound.ogg", 40, 1)

		return src.target


	proc/target_valid(var/mob/living/C)
		var/distance = get_dist(C.loc,src.loc)

		if(distance > src.range)
			return 0
		if (!C)
			return 0
		if (C.health < 0)
			return 0
		if (C.stat == 2)
			return 0
		if (istype(C,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = C
			if (H.resting || H.weakened) // stops it from uselessly firing at people who are already suppressed. It's meant to be a suppression weapon!
				return 0
		if (is_friend(C))
			return 0

		var/angle = get_angle(src,C)

		var/anglemod = (-(angle < 180 ? angle : angle - 360) + 90) //Blatant Code Theft from showLine(), checks to see if there's something in the way of us and the target
		var/crossed_turfs = list()
		crossed_turfs = castRay(src,anglemod,distance)
		for (var/turf/T in crossed_turfs)
			if (T.opacity == 1)
				return 0
			if (T.density == 1)
				return 0

		angle = angle < 0 ? angle+360 : angle // make angles positive
		angle = angle - src.external_angle

		if (angle > 180) // rotate angle and convert into absolute terms from 0, where 0 is the seek-arc midpoint
			angle = abs(360-angle)
		else if (angle < -180)
			angle = abs(360+angle)
		else
			angle = abs(angle)

		if (angle <= (angle_arc_size/2)) //are we in the seeking arc?
			return 1
		return 0


	proc/is_friend(var/mob/living/C) //tried to keep this generic in case you want to make a turret that only shoots monkeys or something
		if (src.emagged)
			return 0 // NO FRIENDS :'[
		if (istype(C,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = C
			if (istype(H.wear_id,/obj/item/card/id/syndicate))
				return 1
		return 0


	proc/shoot(var/turf/target, var/start, var/user, var/bullet = 0)
		if(target == start)
			return

		var/obj/projectile/A = unpool(/obj/projectile)
		if(!A)	return
		A.set_loc(src.loc)
		if (!current_projectile)
			current_projectile = new projectile_type()

		A.proj_data = new current_projectile.type
		A.proj_data.master = A
		A.set_icon()
		A.power = A.proj_data.power
		if(src.current_projectile.shot_sound)
			playsound(src, src.current_projectile.shot_sound, 60)

		if (!istype(target, /turf))
			A.die()
			return

		A.target = target
		A.yo = target:y - start:y
		A.xo = target:x - start:x
		A.shooter = src

		spawn(0)
			A.process()
		return


	proc/set_angle(var/angle)
		angle = angle > 0 ? angle%360 : -((-angle)%360)+360 //limit user input to a sane range!
		var/angle_diff = angle - src.external_angle
		var/new_internal_angle = src.internal_angle + angle_diff

		new_internal_angle = new_internal_angle > 0 ? new_internal_angle%360 : -((-new_internal_angle)%360)+360 //limit user input to a sane range!

		src.animate_turret_turn(src.internal_angle,new_internal_angle)

		src.internal_angle = new_internal_angle
		src.external_angle = angle


	proc/animate_turret_turn(var/curr_ang,var/new_ang)
		var/ang = (new_ang - curr_ang)
		if (abs(ang) > 180) // stops funky turret moving where it flips the long way around
			ang = ang > 0 ? ang - 360 : ang + 360

		var/matrix/transform_original = src.transform
		animate(src, transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0) //blatant code theft from throw_at proc
		animate(transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0) // needs to do in multiple steps because byond takes shortcuts
		animate(transform = matrix(transform_original, ang/3, MATRIX_ROTATE | MATRIX_MODIFY), time = 10/3, loop = 0) // :argh:

	emag_act(var/user, var/emag)
		if(src.emagged)
			return
		src.emagged = 1
		boutput(user,"You short out the safeties on the turret.")
		src.damage_words += "<br><span style='color: red'>Its safety indicator is off!</span>"


/////////////////////////////
//Why not one for security?//
/////////////////////////////

/obj/item/turret_deployer/riot
	name = "N.A.R.C.S."
	desc = "A Nanotrasen Automatic Riot Control System."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "st_deployer"
	health = 125

	spawn_turret(var/turf/user_loc)
		var/direct = get_dir(user_loc,src.loc)
		var/obj/deployable_turret/riot/turret = new /obj/deployable_turret/riot(src.loc,direction=direct)
		turret.health = src.health
		turret.emagged = src.emagged
		turret.damage_words = src.damage_words

/obj/deployable_turret/riot
	name = "N.A.R.C.S."
	desc = "A Nanotrasen Automatic Riot Control System."
	icon = 'icons/obj/turrets.dmi'
	icon_state = "st_off"
	health = 125
	max_health = 125
	wait_time = 20 //wait if it can't find a target
	range = 5 // tiles
	projectile_type = /datum/projectile/bullet/abg
	current_projectile = new/datum/projectile/bullet/abg
	burst_size = 1 // number of shots to fire. Keep in mind the bullet's shot_count
	fire_rate = 1 // rate of fire in shots per second
	angle_arc_size = 60

	New()
		..()
		spawn(src.wait_time)
			if (src.emagged)
				src.projectile_type = /datum/projectile/bullet/a12
				src.current_projectile = new/datum/projectile/bullet/a12

	is_friend(var/mob/living/C)
		if (src.emagged)
			return 0
		if (istype(C,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = C
			if (istype(H.wear_id,/obj/item/card/id)) //This goes off appearance because people can change jobs mid-round... but that also means agent ids are a pretty hard counter. TODO: Fix?
				var/obj/item/card/id/I = H.wear_id
				switch(I.icon_state)
					if("id_sec")
						return 1
					if("id_com")
						return 1
					if("gold")
						return 1
					else
						return 0
		return 0

	spawn_deployer()
		var/obj/item/turret_deployer/riot/deployer = new /obj/item/turret_deployer/riot(src.loc)
		deployer.health = src.health
		deployer.emagged = src.emagged
		deployer.damage_words = src.damage_words

	emag_act(var/user, var/emag)
		..()
		src.projectile_type = /datum/projectile/bullet/a12
		src.current_projectile = new/datum/projectile/bullet/a12

/////////////////////////////
//       User Manuals      //
/////////////////////////////

/obj/item/paper/nast_manual
	name = "paper- 'Nuclear Agent Sentry Turret Manual'"
	info = {"<h4>Nuclear Agent Sentry Turret Manual</h4>
	Congratulations, on your purchase of a Nuclear Agent Sentry Turret!<br>
	This a turret that fires at non-syndicate threats in a 30 degree arc.<br>
	Weld it to the floor to secure it, screwdriver to turn it on, and wrench it to set the angle.<br>
	The firing angle is set in terms of degrees clockwise from North.<br>
	Inputting a negative angle will result in a setting in terms of degrees counterclockwise from North.<br>
	Welding the turret while it is active will allow you to perform repairs.<br>"}

/obj/item/paper/narcs_manual
	name = "paper- 'Nanotrasen Automatic Riot Control System'"
	info = {"<h4>Nanotrasen Automatic Riot Control System</h4>
	Congratulations, on your purchase of a Nanotrasen Automatic Riot Control System!<br>
	This a turret that fires at non-security and non-command threats in a 60 degree arc.<br>
	Weld it to the floor to secure it, screwdriver to turn it on, and wrench it to set the angle.<br>
	The firing angle is set in terms of degrees clockwise from North.<br>
	Inputting a negative angle will result in a setting in terms of degrees counterclockwise from North.<br>
	Welding the turret while it is active will allow you to perform repairs.<br>"}