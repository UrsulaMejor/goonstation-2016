//WAND PARENT

/obj/item/wand
	name = "wand"
	desc = "A magic wand, like the kind used for magic."
	icon = 'icons/obj/wand.dmi'
	icon_state = "wand"
	inhand_image_icon = 'icons/obj/wand.dmi'
	item_state = "wand"
	var/cooldown = 30 //10ths of seconds
	var/charges = -1 // how many casts the wand holds. Set to -1 for inf
	var/on_cooldown = 0
	var/cast_message = "creating sparkles!"

	New()
		..()
		src.set_vars()
		src.set_appearance()

	get_desc()
		if(charges > 0)
			. += "<br><span style=\"color:blue\">It has [charges] charges left.</span>"
		else if (charges == 0)
			. += "<br><span style=\"color:red\">It appears to be out of charges.</span>"

	proc/set_vars()
		return

	proc/set_appearance()
		src.color = rgb(rand(255),rand(255),rand(255))
		return

	proc/cast_check(var/atom/target,var/source_turf, var/mob/user)
		return 1

	proc/cast(var/atom/target,var/source_turf, var/mob/user)
		if(on_cooldown)
			return 0
		if(!charges)
			return 0
		if(charges > 0)
			charges--
		if(!cast_check(target,source_turf,user))
			user.visible_message("<span style=\"color:red\">[user] points [src] at [target], but nothing happens.</span>")
			return 0

		on_cooldown = 1
		spawn(cooldown)
			on_cooldown = 0

		user.visible_message("<span style=\"color:red\"><b>[user] points [src] at [target], [cast_message]</b></span>")
		blink(get_turf(target))
		return 1

	pixelaction(atom/target, params, mob/user, reach)
		if (!isturf(user.loc))
			return 0
		cast(target, get_turf(user), user)
		return 1

	attack(mob/M as mob, mob/user as mob)
		return

	attack_self(mob/user as mob)
		user.visible_message("<span style=\"color:red\">[user] twirls [src]!</span>")

// TRANSMUTATION WANDS

obj/item/wand/transmutation
	var/stored_material = null
	var/list/possible_materials = null
	cast_message = ""

	New()
		spawn(1)
			if(!src.possible_materials)
				src.possible_materials = material_cache
				src.stored_material = pick(possible_materials)
			..()

	set_vars()
		src.setMaterial(getCachedMaterial(stored_material))
		cast_message = "changing it into [stored_material]!"

	set_appearance()
		return

	cast_check(var/atom/target,var/source_turf, var/mob/user)
		if(!istype(target,/obj/) && !istype(target,/turf/))
			return 0
		return ..()

	cast(var/atom/target,var/source_turf, var/mob/user)
		if(..(target,source_turf,user))
			target.setMaterial(getCachedMaterial(stored_material))

	proc/pick_material(mob/user as mob)
		. = stored_material
		var/mat = input(usr,"Select Material:","Material",null) in possible_materials
		if(mat)
			. = mat

	attack_self(mob/user as mob)
		user.visible_message("<span style=\"color:red\">[user] twirls [src]!</span>")
		var/mat = pick_material(user)
		if(!mat)
			return
		stored_material = mat
		src.set_vars()

obj/item/wand/transmutation/limited
	charges = 13

	New()
		spawn(1)
			if(!src.possible_materials)
				src.possible_materials = list("slag","leather","bone","mauxite","pharosium","molitz","ice","koshmarite")
				src.stored_material = pick(possible_materials)
			..()

	pick_material(mob/user as mob)
		if(!src.charges)
			return
		charges--
		. = stored_material
		var/mat = pick(possible_materials)
		if(prob(10))
			mat = pick("erebite","cerenkite")
		if(mat)
			. = mat

//SPELL WAND

obj/item/wand/spell
	name = "wand of fireball"
	var/my_spell = null //as path
	cast_message = "casting its stored spell!"

	New()
		if(!my_spell)
			my_spell = /datum/targetable/spell/fireball
		..()

	cast(var/atom/target,var/source_turf, var/mob/user)
		if(..(target,source_turf,user))
			var/datum/abilityHolder/wizard/W = new()
			var/datum/targetable/spell/A = new my_spell
			A.holder = W
			W.owner = user
			A.requires_robes = 0
			A.cast(target)

obj/item/wand/spell/mist
	name = "wand of phase shift"

	New()
		if(!my_spell)
			my_spell = /datum/targetable/spell/phaseshift
		..()