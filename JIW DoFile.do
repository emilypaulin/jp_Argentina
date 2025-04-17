stop
clear

cd "/Users/emilypaulin/JIW/data"

*Install DID packages
ssc install eventdd 
ssc install matsort 
ssc install reghdfe 
ssc install ftools
ssc install drdid, all replace
ssc install csdid, all replace

*Datasets access

**Mortality as columns, years as individual entries
use infantmortality_longer, clear 
reshape long mortalidad_infantil_@, i(year) j() string
rename _j province
rename mortalidad_infantil_ mortality
replace province = "buenos_aires" if province == "buenosaires"
replace province = "entre_rios" if province == "entrerios"
replace province = "la_pampa" if province == "lapampa"
replace province = "la_rioja" if province == "larioja"
replace province = "rio_negro" if province == "rionegro"
replace province = "san_juan" if province == "sanjuan"
replace province = "san_luis" if province == "sanluis"
replace province = "santa_cruz" if province == "santacruz"
replace province = "santa_fe" if province == "santafe"
replace province = "santiago_del_estero" if province == "santiagodele"
replace province = "tierra_del_fuego" if province == "tierradelfue"
replace province = "santa_cruz" if province == "santacruz"
save mortality_long, replace
**Years as columns
use infantmortality_longer_reshaped, clear
**Years as columns
use ArgRepresentation, clear
**Representation in long form
use ArgRepresentation_reshaped, clear
drop in 8/37
drop *_Senate
drop Federal_Capital 
rename Average argentina
rename Buenos_Aires_House buenos_aires
rename Catamarca_House catamarca
rename Chaco chaco
rename Chubut chubut
rename Cordoba_House cordoba
rename Corrientes_House corrientes
rename Entre_Rios_House entre_rios
rename Formosa formosa
rename Juyjuy jujuy
rename La_Pampa la_pampa
rename La_Rioja la_rioja
rename Mendoza_House mendoza
rename Misiones misiones
rename Neuquen neuquen
rename Rio_Negro rio_negro
rename Salta_House salta
rename San_Juan san_juan
rename San_Luis_House san_luis
rename Santa_Cruz santa_cruz
rename Santa_Fe_House santa_fe
rename Santiago_del_Estero santiago_del_estero
rename Tierra_del_Fuego tierra_del_fuego
rename Tucuman_House tucuman

rename * province*
rename provinceyear year
reshape long province@, i(year) j() string
rename province representation
rename _j province
save ArgRepresentation_long_nosenate, replace
*ArgRepresentation_long has senate included but names still not good

**Merged dataset, locations as columns, years as rows
use merged_data, clear
drop _merge
rename mortalidad_infantil_* mi_*
save, replace

*Load quota implementation data. 
import delimited using "Minimum Quota Enactment.csv", clear
rename juyjuy jujuy
save minquota, replace

use minquota, clear
rename * me_*
*Renaming to minimum event
rename me_year year
*Create a binary variable for if they have the minimum quota: bme_*
foreach var of varlist me_argentina-me_tucuman {
    gen b`var' = (`var' >= 0)
}
save, replace

reshape long me_@ bme_@, i(year) j() string
rename _j province
rename me_ minquota
rename bme_ bminquota
save minquota_long, replace

*New merged dataset, long
use minquota_long, clear
merge 1:m year province using ArgRepresentation_long_nosenate
drop _merge
save merged_data_long, replace

gen eventX = .
replace eventX = year if minquota == 0
tab minquota
*All treated units experienced the event between minquota == -1 and 9, so: 
clonevar minquota_accum = minquota
replace minquota_accum = -1 if minquota_accum < -1 & minquota_accum != .
replace minquota_accum = -1 if minquota_accum > 9 & minquota_accum != .
tab minquota_accum, gen(x)
save merged_data_long, replace

*Merge with infant mortality
use merged_data_long, clear
merge 1:m year province using mortality_long
drop _merge
save merged_data_long1, replace

sort province
by province: replace eventX = eventX[_n-1] if missing(eventX)
by province: replace eventX = eventX[_n+1] if missing(eventX)
drop if province == "caba"
save merged_data_long2, replace

*Merged dataset with no controls


********************************************************************************
							*Add control data*
********************************************************************************
*Population data
import delimited "poblacion_identificada_provincia_enero_2023.csv", clear
sort provincia_id
tab provincia_id

import delimited "tasa-natalidad-deis-2000-2022.csv", clear

import delimited "tasa-desempleo-valores-anuales.csv", clear

import delimited "indice-precios-al-consumidor-apertura-por-categorias-base-diciembre-2016-mensual.csv", clear

import delimited "emae-valores-anuales-indice-base-2004-mensual.csv", clear

import delimited "poburb_18a65_subocupdemandante.csv", clear

use WVS_trends_3_0, clear
decode COW_NUM, gen(country)
drop if country != "Argentina"

import delimited "series-tiempo.csv", clear

*Economic indicators
import delimited "indicadores-provinciales.csv", clear
tab actividad_producto_nombre
tab indicador
tab indice_tiempo
*vars include mortalidad general, infantil, materna, poblacion
*I think I'll merge population, general death, maternal mortality, PBG total

*keep only the variables I want
keep valor indice_tiempo alcance_nombre indicador actividad_producto_nombre
keep if (indicador == "PBG - Base 1993" | indicador == "PBG - Base 2004" | actividad_producto_nombre == "Mortalidad General" | actividad_producto_nombre == "Mortalidad Materna" | actividad_producto_nombre == "Población")

gen date = date(indice_tiempo, "YMD")
format date %td
gen year = year(date)
bysort year indicador alcance_nombre: keep if _n == 1
sort indicador alcance_nombre year

drop date indice_tiempo
order year

rename alcance_nombre province
replace province = "argentina" if province == "ARGENTINA"
replace province = "argentina" if province == "Argentina"
replace province = "buenos_aires" if province == "BUENOS AIRES"
replace province = "catamarca" if province == "CATAMARCA"
replace province = "chaco" if province == "CHACO"
replace province = "chubut" if province == "CHUBUT"
replace province = "cordoba" if province == "CORDOBA"
replace province = "corrientes" if province == "CORRIENTES"
replace province = "entre_rios" if province == "ENTRE RIOS"
replace province = "formosa" if province == "FORMOSA"
replace province = "jujuy" if province == "JUJUY"
replace province = "la_pampa" if province == "LA PAMPA"
replace province = "la_rioja" if province == "LA RIOJA"
replace province = "mendoza" if province == "MENDOZA"
replace province = "misiones" if province == "MISIONES"
replace province = "neuquen" if province == "NEUQUEN"
replace province = "rio_negro" if province == "RIO NEGRO"
replace province = "salta" if province == "SALTA"
replace province = "san_juan" if province == "SAN JUAN"
replace province = "san_luis" if province == "SAN LUIS"
replace province = "santa_cruz" if province == "SANTA CRUZ"
replace province = "santa_fe" if province == "SANTA FE"
replace province = "santiago_del_estero" if province == "SANTIAGO DEL ESTERO"
replace province = "tierra_del_fuego" if province == "TIERRA DEL FUEGO"
replace province = "tucuman" if province == "TUCUMAN"
replace province = "capital_federal" if province == "CAPITAL FEDERAL"
drop if indicador == "PBG - Base 1993"
drop if indicador == "Tasa"
tab indicador
replace indicador = "Poblacion" if indicador == "Proyecciones"
drop actividad_producto_nombre
order year province indicador
drop indice_tiempo date
replace indicador = "PBG" if indicador == "PBG - Base 2004"
save econ, replace

use econ, clear
reshape wide valor, i(year province) j(indicador) string
rename valorPBG pbg
rename valorPoblacion poblacion
gen logpbg = log(pbg)
drop if year == 2020
drop if year == 2021
drop if year == 2022
drop if year == 2023
drop if year == 2024
drop if year == 2025
rename capital_federal buenos_aires
save econ, replace

use merged_data_long2, clear
merge 1:m year province using econ
drop if eventX == .
gen logpoblacion = log(poblacion)
drop _merge
save merged_data_long4, replace

encode province, gen(provinceencoded)
xtset provinceencoded year
gen logpoblacion = log(poblacion)
drop _merge
gen gdppc = pbg/poblacion
save merged_data_long3, replace

********************************************************************************
							*Now for the real analysis*
********************************************************************************
*Simple regression --not used in paper
use merged_data_long4, clear

reg mortality representation 
outreg2 using simplereg.doc, replace
twoway (scatter mortality representation, yscale(range(0,.)) title(Women's Representation and Infant Mortality) ytitle(Infant Mortality) xtitle(Women's Representation in Legislature)) (lfit mortality representation)

reg mortality representation logpbg logpoblacion poblacion pbg 
outreg2 using simplereg.doc, append
*Panel regression -- table 2 and graph 3 in paper

xtreg mortality representation, robust
outreg2 using panelregnofe.doc, replace
xtreg mortality representation logpbg, robust
outreg2 using panelregnofe.doc, append
xtreg mortality representation logpbg logpoblacion pbg poblacion, robust
outreg2 using panelregnofe.doc, append

xtreg mortality representation i.year, fe robust
outreg2 using panelreg.doc, replace
xtreg mortality representation i.year logpbg, fe robust
outreg2 using panelreg.doc, append
xtreg mortality representation logpoblacion i.year, fe robust

*eventdd
eventdd representation, timevar(minquota) leads(3) lags(3) accum
outreg2 event.doc, replace
eventdd representation, timevar(minquota) leads(5) lags(5) accum

eventdd mortality, timevar(minquota) leads(5) lags(5) accum

*csdid 
csdid representation, ivar(provinceencoded) time(year) gvar(eventX) event notyet
estat event 
outreg2 using csdid.doc, replace
csdid_plot

csdid mortality, ivar(provinceencoded) time(year) gvar(eventX) event notyet
estat event
csdid_plot

*Accounting for election year shenanigans
gen election_year_eventX = .
replace election_year_eventX = 1994 if eventX <= 1994 
replace election_year_eventX = 1998 if eventX <= 1998 & eventX > 1994
replace election_year_eventX = 2002 if eventX <= 2002 & eventX > 1998
replace election_year_eventX = 2006 if eventX <= 2006 & eventX > 2002
replace election_year_eventX = 2010 if eventX <= 2010 & eventX > 2006
replace election_year_eventX = 2014 if eventX <= 2014 & eventX > 2010

csdid representation, ivar(provinceencoded) time(year) gvar(election_year_eventX) event notyet
estat event
csdid_plot
outreg2 using csdid.doc, replace

csdid mortality, ivar(provinceencoded) time(year) gvar(election_year_eventX) event notyet
estat event
csdid_plot

********************************************************************************
							*redoing graphs*
********************************************************************************

*Sharp discontinuities in women's rep
twoway (line representation year if province == "misiones", xline(1993, lcolor(navy))) ///
(line representation year if province == "buenos_aires", xline(1997, lcolor(maroon))) ///
(line representation year if province == "formosa", xline(1995, lcolor(green))), ///
ytitle(Women's Representation) xtitle(Year) title(Representation over Time) xscale(range(1990 2014)) ///
legend(label(1 "Misiones") label(2 "Buenos Aires") label(3 "Formosa")) 

xtline representation, overlay legend(off) title(Women's Representation Over Time)
xtline mortality, overlay title(Infant Mortality Over Time) legend(off) ytitle(Infant Mortality)

*Sharp discontinuities in infant mortality
twoway (line mortality year if province == "misiones", xline(1993, lcolor(navy))) ///
(line mortality year if province == "buenos_aires", xline(1997, lcolor(maroon))) ///
(line mortality year if province == "formosa", xline(1995, lcolor(green))), ///
ytitle(Infant Mortality) xtitle(Year) title(Infant Mortality over Time) ///
legend(label(1 "Misiones") label(2 "Buenos Aires") label(3 "Formosa"))



********************************************************************************
						*Old code I'm reluctant to delete*
********************************************************************************
save infantmortality_longer, replace
use infantmortality_longer, clear

*Old merged dataset, wide
merge 1:m year using merged_data
drop _merge
save merged_data1, replace
*Naming conventions: vf
**mortalidad_infantil_buenosaires
**Buenos_Aires_House, Buenos_Aires_Senate


*Preliminary regression analysis to show correlation and trends (done on the merged_data1 set)
use merged_data1, clear
**Aggregate
reg mortalidad_infantil_argentina Average
* do another with controls when I have them

reg bme_argentina Federal_Capital
reg bme_tucuman Tucuman_House
reg bme_tucuman mi_tucuman

*Graphs
**Aggregate
twoway scatter mortalidad_infantil_argentina year, title(Infant Mortality) ytitle(Infant Mortality) xtitle(Year) yscale(range(0,.))
twoway scatter Average year, title(Women's Representation) ytitle(Representation) xtitle(Year) yscale(range(0,.))
twoway scatter Average mortalidad_infantil_argentina, title(Mortality and Representation) ytitle(Representation) xtitle(Infant Mortality) yscale(range(0,.))

**Sharp discontinuities
twoway scatter Chubut year, yscale(range(0,.)) title(Chubut) ytitle(Representation) xtitle(Year)
twoway scatter Buenos_Aires_House year, yscale(range(0,.)) title(Buenos Aires House) ytitle(Representation) xtitle(Year)
twoway scatter Formosa year, yscale(range(0,.)) title(Formosa) ytitle(Representation) xtitle(Year)

*DID regression
eventdd mortality representation, timevar(minquota)
eventdd mortality, timevar(minquota)
eventdd representation, timevar(minquota)

*This gets an error of some sort but includes accum option
eventdd mortality, timevar(minquota_accum), accum lags(-1) leads(9) 

*Other thing to graph it, model pasted here but will need to look at it more
reghdfe gdppc x1-x4 x6-x12, absorb(country1) vce(cluster country1)
