/obj/item/plank
	name = "wooden plank"
	desc = "My best friend plank!"
	icon = 'icons/obj/hydroponics/hydromisc.dmi'
	icon_state = "plank"
	force = 4.0
		//cogwerks - burn vars
	burn_point = 400
	burn_output = 1500
	burn_possible = 1
	health = 50
	//
	stamina_damage = 40
	stamina_cost = 40
	stamina_crit_chance = 10

	attack_self()
		boutput(usr, "<span style=\"color:blue\">Now building wood wall. You'll need to stand still.</span>")
		var/turf/T = get_turf(usr)
		sleep(30)
		if(usr.loc == T)
			if(!locate(/obj/structure/woodwall) in T)
				var/obj/structure/woodwall/N = new /obj/structure/woodwall(T)
				N.builtby = usr.real_name
				qdel(src)
			boutput(usr, "<span style=\"color:red\">There's already a barricade here!</span>")
			return
		else
			return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/staple_gun))
			var/obj/item/staple_gun/G = W
			if (G.staple.shot_sound)
				playsound(user, G.staple.shot_sound, 50, 1)
			var/obj/item/sign_post_parts/S = new /obj/item/sign_post_parts(get_turf(usr))
			S.health = src.health
			user.u_equip(src)
			qdel(src)
		else
			..()