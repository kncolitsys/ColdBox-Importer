<cfset temp = request.tap.getPage().head />
<cfparam name="temp.coldbox" type="string" default="" />
<cfoutput>#temp.coldbox#</cfoutput>
