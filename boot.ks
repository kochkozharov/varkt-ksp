print "3".
wait 1.
print "2".
wait 1.
print "1".
wait 1.
print "Поехали!".

lock steering to heading(90,90).
lock throttle to 1.
stage.
wait until stage:solidfuel<1.
print "Твердотопливная вертикальная ступень отработала".
print "Жидкотопливная ступень отрабатывает тангаж с 90 до 40 градусов".
stage.
set maxFuel to stage:oxidizer.
lock steering to heading(90,90-50*(1-stage:oxidizer/maxFuel)). //с 90 до 40 градусов
wait until stage:oxidizer<1.
lock steering to heading(90,40).
lock throttle to 0.
wait 1.
stage.

until eta:apoapsis<1
{
    clearScreen.
    print "Летим по инерции".
    print "Ожидаемое время прибытия в апоцентр:  "+ eta:apoapsis.
}
//начинаем циркуляризацию орбиты
stage.
lock throttle to 1.
set stopCirc to false.
until stopCirc {
    set circData to circularization.
    if circData[4]<0 //выход из цикла при достижении первой космической
        set stopCirc to true.
    else if circData[4] < 100 //если дельта первой космиечской менее 100м/c, то плавно снижаем тягу
        lock throttle to max(circData[4]/100, 0.01).
    lock steering to heading(90, circData[0]). //выставляем тангаж на угол Фи
    clearScreen.
    print "Вычисление угла Фи для получения круглой орбиты".
    print "Phi: " + circData[0].
    print "Горизонтальная скорость: " + circData[1].
    print "Вертикальная скорость: " + circData[2].
    print "Первая космическая на данной высоте: " + circData[3].
    print "Дельта первой космической dVh: " + circData[4].
    print "Delta A: " + circData[5].

}

lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
wait 1.
clearScreen.

print "На орбите!".
wait 5.
print "Apoapsis: " + ship:orbit:apoapsis.
wait 1.
print "Periapsis: " + ship:orbit:periapsis.
wait 1.
print "Eccenticity: " + ship:orbit:eccentricity.

print "Нажмите любую клавишу 3 раза для схода с орбиты".
terminal:input:getchar().
terminal:input:getchar().
terminal:input:getchar().
clearScreen.
print "Сходим с орбиты!".
print "Разворот в обратную сторону, чтобы хитшилд защитил ракету".
lock steering to retrograde.
wait 10.
lock throttle to 1.
wait until  stage:oxidizer<1.
lock throttle to 0.
print "Готово".
wait 1.
stage.
lock steering to -ship:velocity:surface.
wait until alt:radar < 1000.
unlock steering.
wait until (status= "LANDED") or (status="SPLASHED").
print "Мы дома...".

//возвращает различные параметры, необходимые для циркуляризации орбиты
function circularization
{
    set Vh to vxcl(ship:up:vector, ship:velocity:orbit):mag. //Горизонтальная скорость.
    set Vz to ship:verticalspeed. //вериткальная скорость
    set Rad to ship:body:radius+ship:altitude. //радиус орбиты.
    set Vorb to sqrt(ship:body:mu/Rad). //первая космическая на данной высоте
    set Gorb to ship:body:mu/Rad^2. //ускорение свободного падение на данной высоте
    set AThr to engThrustIsp[0]*throttle/(ship:mass). //ускорение, которое сообщают ракете активные двигатели в текущий момент
    set ACentr to Vh^2/Rad. //центростремительное ускорение
    set DeltaA to Gorb-ACentr-max(min(Vz,2),-2). //разность ускорения свободного падения и центростемительного ускорения с поправкой на понижение вертикальной скорости
    set Phi to arcsin(DeltaA/AThr). // Считаем угол к горизонту так, чтобы держать вертикальную скорость = 0
    set dVh to Vorb-Vh. //Дельта первой космической
    return list(Phi, Vh, Vz, Vorb, dVh, DeltaA).
}

function engThrustIsp
{
    set engs to list().
    engs:clear.
    set engs_thrust to 0.
    set engs_isp to 0.
    list engines in myengines.
    //добавляем все активные движки в engs
    for eng in myengines {
        if eng:ignition = true and eng:flameout = false {
            engs:add(eng).
        }
    }
    //суммарная тяга и средний удельный импульс всех активных движков
    for eng in engs {
        set engs_thrust to engs_thrust+eng:availablethrust.
        set engs_isp to engs_isp+eng:isp.
    }
    return list(engs_thrust, engs_isp/engs:length).
}