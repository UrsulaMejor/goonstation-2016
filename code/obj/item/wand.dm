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
		on_cooldown = 1
		spawn(cooldown)
			on_cooldown = 0
		if(charges && cast_check(target,source_turf,user))
			if(charges>0)
				charges--
		else
			user.visible_message("<span style=\"color:red\">[user] points [src] at [target], but nothing happens.</span>")
			return 0
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



obj/item/wand/transmutation
	var/stored_material = null
	cast_message = ""

	New()
		spawn(10)
			src.stored_material = pick(material_cache)
			..()

	set_vars()
		src.setMaterial(getCachedMaterial(stored_material))
		cast_message = "changing it into [stored_material]!"

	set_appearance()
		return

	cast_check(var/atom/target,var/source_turf, var/mob/user)
		if(!istype(target,/obj/) && !istype(target,/turf/))
			return 0
		return 1

	cast(var/atom/target,var/source_turf, var/mob/user)
		if(..(target,source_turf,user))
			target.setMaterial(getCachedMaterial(stored_material))

	attack_self(mob/user as mob)
		user.visible_message("<span style=\"color:red\">[user] twirls [src]!</span>")
		var/mat = input(usr,"Select Material:","Material",null) in material_cache
		if(!mat)
			return
		stored_material = mat
		src.set_vars()