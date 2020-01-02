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

	New()
		..()
		src.set_vars()
		src.set_appearance()

	proc/set_vars()
		return

	proc/set_appearance()
		src.color = rgb(rand(255),rand(255),rand(255))
		return

	proc/cast(var/atom/target,var/source_turf, var/mob/user)
		if(on_cooldown)
			return
		on_cooldown = 1
		spawn(cooldown)
			on_cooldown = 0
		if(charges)
			if(charges>0)
				charges--
		else
			user.visible_message("<span style=\"color:red\">[user] points [src] at [target], but nothing happens.</span>")
			return
		user.visible_message("<span style=\"color:red\"><b>[user] points [src] at [target], creating sparkles!</b></span>")
		blink(get_turf(target))
		return

	pixelaction(atom/target, params, mob/user, reach)
		if (reach)
			return 0
		if (!isturf(user.loc))
			return 0
		var/pox = text2num(params["icon-x"]) - 16
		var/poy = text2num(params["icon-y"]) - 16
		cast(target, get_turf(user), user, pox, poy)
		return 1
