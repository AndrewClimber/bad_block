select 
	e.effort_s, e.is_agreement, e.agreement_description,
	e.work_construction_object_s, e.work_class_s, e.work_s,
	e.description, e.place_s, e.is_overtime, e.begin_date,
	e.duration, e.state_s, e.owner_user_s, wc.description,
	o.description, w.name, work_place.name,
	effort_state.name,
	erp.erp_pkg.makeFIO(own_user.last_name, own_user.first_name, own_user.second_name) owner_user_fio,
	co.name,w.owner_user_s,
	o.owner_user_s,wc.owner_user_s,w.state_s,w_part.name,w_config.type_s,
	own_user.last_name, own_user.first_name, own_user.second_name from 
	erp.construction_object co,
	erp.effort e,
	erp.work_class wc,
	erp.work_construction_object o,
	erp.work w,
	erp.dictionary work_place,
	erp.dictionary effort_state,
	erp.users_actual_now own_user,
	erp.work_part w_part,
	erp.work_config w_config,
	erp.department d
where 
	w.type_s = w_config.type_s
	and e.work_part_s = w_part.work_part_s(+)
	and o.construction_object_s= co.construction_object_s(+)
    and e.work_class_s = wc.work_class_s(+)
    and e.work_construction_object_s = o.work_construction_object_s(+)
    and e.work_s = w.work_s
    and e.place_s = work_place.dictionary_s(+)
    and e.state_s = effort_state.dictionary_s(+)
    and e.owner_user_s = own_user.user_s
    and own_user.department_s = d.department_s
    and e.state_s = 1213
    and e.effort_s in (
  select effort_s from erp.effort_agreement
  where agr_user_s = 1580670 and agr_type_s = 1246
)
    order by e.begin_date desc,owner_user_fio