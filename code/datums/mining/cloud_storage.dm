#define ROCKBOX_STANDARD_FEE 5
var/global/rockbox_client_fee_min = 1
var/global/rockbox_client_fee_pct = 10
var/global/rockbox_premium_purchased = 0

/obj/machinery/ore_cloud_storage_container
	name = "Rockbox&trade; Ore Cloud Storage Container"
	desc = "This thing stores ore in \"the cloud\" for the station to use. Best not to think about it too hard."
	icon = 'icons/obj/mining.dmi'
	icon_state = "ore_storage_unit"
	density = 1
	anchored = 1
	var/base_material_class = /obj/item/raw_material/
	var/list/sell_price = list()
	var/list/for_sale = list()
	var/list/ores = list()
	var/list/sellable_ores = list()
	var/health = 100
	var/broken = 0

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)

		if (!O || !user)
			return

		if(!istype(user,/mob/living/))
			boutput(user, "<span style=\"color:red\">Only living mobs are able to use the storage container's quick-load feature.</span>")
			return

		if (!istype(O,/obj/))
			boutput(user, "<span style=\"color:red\">You can't quick-load that.</span>")
			return

		if(get_dist(O,user) > 1)
			boutput(user, "<span style=\"color:red\">You are too far away!</span>")
			return

		else if (istype(O, /obj/storage/crate/) && src.accept_loading(user,1))
			if (O:welded || O:locked)
				boutput(user, "<span style=\"color:red\">You cannot load from a crate that cannot open!</span>")
				return

			user.visible_message("<span style=\"color:blue\">[user] uses [src]'s automatic loader on [O]!</span>", "<span style=\"color:blue\">You use [src]'s automatic loader on [O].</span>")
			var/amtload = 0
			for (var/obj/item/M in O.contents)
				if (!istype(M,src.base_material_class))
					continue
				src.load_item(M)
				amtload++
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] materials loaded from [O]!</span>")
			else boutput(user, "<span style=\"color:red\">No material loaded!</span>")

		else if (istype(O, /obj/item/) && src.accept_loading(user,1))
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing materials into [src]!</span>")
			var/staystill = user.loc
			for(var/obj/item/M in view(1,user))
				if (!O)
					continue
				if (!istype(M,O.type))
					continue
				if (!istype(M,src.base_material_class))
					continue
				if (O.loc == user)
					continue
				if (O in user.contents)
					continue
				src.load_item(M)
				sleep(0.5)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing materials into [src]!</span>")
			src.update_ores()

		else ..()

		src.updateUsrDialog()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, src.base_material_class) && src.accept_loading(user))
			user.visible_message("<span style=\"color:blue\">[user] loads [W] into the [src].</span>", "<span style=\"color:blue\">You load [W] into the [src].</span>")
			src.load_item(W,user)
			src.update_ores()

		else
			src.health = max(src.health-W.force,0)
			src.check_health()
			..()

	proc/check_health()
		if(!src.health)
			src.broken = 1
			src.icon_state = "ore_storage_unit-broken"
			src.update_sellable()

	proc/load_item(var/obj/item/O,var/mob/living/user)
		if (!O)
			return
		if(O.amount == 1)
			O.set_loc(src)
			if (user && O)
				user.u_equip(O)
				O.dropped()
		else if(O.amount>1)
			O.set_loc(src)
			for(O.amount,O.amount > 0, O.amount--)
				new O.type(src)
			if (user && O)
				user.u_equip(O)
				O.dropped()
			qdel(O)
		else
			return // uhhhhhh


	proc/accept_loading(var/mob/user,var/allow_silicon = 0)
		if (!user)
			return 0
		if (src.stat & BROKEN || src.stat & NOPOWER)
			return 0
		if (!istype(user, /mob/living/))
			return 0
		if (istype(user, /mob/living/silicon) && !allow_silicon)
			return 0
		var/mob/living/L = user
		if (L.stat || L.transforming)
			return 0
		return 1

	proc/update_ores()
		var/list/new_ores = list()
		for(var/obj/item/raw_material/R in src.contents)
			if(!(R.material_name in new_ores))
				new_ores += R.material_name
				new_ores[R.material_name] = 1

			else
				new_ores[R.material_name]++
		src.ores = new_ores
		src.update_sellable()
		return

	proc/update_sellable()
		var/list/new_sellable_ores = list()
		if(src.broken)
			src.sellable_ores = new_sellable_ores
			return
		for(var/ore in src.ores)
			if(ore in src.for_sale)
				if(for_sale[ore])
					if(!(ore in new_sellable_ores))
						new_sellable_ores += ore
						new_sellable_ores[ore] = ores[ore]
					else
						continue
				else
					continue

		src.sellable_ores = new_sellable_ores


	attack_hand(var/mob/user as mob)

		var/list/ores = src.ores

		user.machine = src
		var/dat = "<B>[src.name]</B>"

		dat += "<br><HR>"

		if (stat & BROKEN || stat & NOPOWER)
			dat = "The screen is blank."
			user << browse(dat, "window=mining_dropbox;size=400x500")
			onclose(user, "mining_dropbox")
			return

		if(ores.len)
			for(var/ore in ores)
				var/sellable = 0
				var/price = 0
				if(src.sell_price[ore] != null)
					price = sell_price[ore]
				if(src.for_sale[ore] != null)
					sellable = src.for_sale[ore]
				dat += "<B>[ore]:</B> [ores[ore]] (<A href='?src=\ref[src];sellable=[ore]'>[sellable ? "For Sale" : "Not For Sale"]</A>) (<A href='?src=\ref[src];price=[ore]'>$[price] per ore</A>) (<A href='?src=\ref[src];eject=[ore]'>Eject</A>)<br>"
		else
			dat += "No ores currently loaded.<br>"

		user << browse(dat, "window=mining_dropbox;size=450x500")
		onclose(user, "mining_dropbox")



	Topic(href, href_list)

		if(stat & BROKEN || stat & NOPOWER)
			return

		if(usr.stat || usr.restrained())
			return

		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))))
			usr.machine = src

			if (href_list["eject"])
				var/ore = href_list["eject"]
				var/turf/ejectturf = get_turf(usr)

				src.eject_ores(ore,ejectturf,0,0,usr)

			if (href_list["price"])
				var/ore = href_list["price"]
				var/new_price = null
				new_price = input(usr,"What price would you like to set? (Min 0)","Set Sale Price",null) as num
				new_price = max(0,new_price)
				if(src.sell_price[ore])
					sell_price[ore] = new_price
				else
					sell_price += ore
					sell_price[ore] = new_price

			if (href_list["sellable"])
				var/ore = href_list["sellable"]
				if(src.for_sale[ore])
					for_sale[ore] = !for_sale[ore]
				else
					for_sale += ore
					for_sale[ore] = 1
				update_sellable()

			src.updateUsrDialog()
		return

	proc/eject_ores(var/ore, var/turf/ejectturf, var/ejectamt, var/transmit = 0, var/user as mob)
		for(var/obj/item/raw_material/R in src.contents)
			if (R.material_name == ore)
				if (!ejectamt)
					ejectamt = input(usr,"How many ores do you want to eject?","Eject Ores") as num
				if ((ejectamt <= 0 || get_dist(src, user) > 1) && !transmit)
					break
				if (!ejectturf)
					break
				R.set_loc(ejectturf)
				ejectamt--
				if (ejectamt <= 0)
					break
		if(transmit)
			flick("ore_storage_unit-transmit",src)
			showswirl(ejectturf)
			leaveresidual(ejectturf)

		src.update_ores()