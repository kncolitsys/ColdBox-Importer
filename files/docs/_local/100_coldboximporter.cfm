<cfset plugin = getIoC().getContainer("plugins").getBean("coldbox") />

<cfoutput>
	<cfsavecontent variable="tap.view.content">
	#htlib.show(docPage(plugin.getValue("name") & " " 
		& plugin.getValue("version") & " " & plugin.getValue("revision")))#
	
	<p>There are a great many dedicated developers in the ColdFusion community, 
	and together they've produced quite a lot of good software. Why should we 
	limit ourselves to only a particular subset of their contributions? This 
	plugin imports existing ColdBox applications to run within the context of 
	your onTap framework application. So for example if you found a forum 
	application that you liked, but you're using the onTap framework and the 
	forum was written in ColdBox, why shouldn't you still be able to use that 
	forum application?</p>
	
	<p>Importing the content from the ColdBox application into your own also 
	helps with issues like single-sign-on wherein you already have a member 
	management system, and you don't want your users to need two separate sets 
	of login credentials for your site (one for the site and another for the forum). 
	Having the application within the context of your existing application 
	framework makes it easier to sync-up the forum user database with your 
	existing user database.</p>
	
	#docSection("Importing An Application")# 
	
	<p>Once you've got the ColdBox importer installed, simply navigate to 
	the plugin manager (you're probably already there), select the manage 
	button next to the ColdBox Importer in your list of plugins. In the 
	Import form at the top, enter a name to identify the imported application, 
	the physical file location of the application's root directory (where 
	the Application.cfc is located) and press the Import button. 
	
	#docSection("Creating an Installer")# 
	
	<p>If you've got a ColdBox application you'd like to distribute via the 
	onTap framework, you can create an installer for your specific application 
	that will help make integration easier. In your installer, all you need to 
	do is fetch the ColdBox container from the framework's IoC Manager and 
	call the install() method.</p>
	
	<p>Example: &lt;cfset getTap().getIoC().getContainer("coldbox").install("myapp",ExpandPath("/path/to/app")) /&gt;</p>
	
	#docSection("Integrating ColdBox Events")# 
	
	<p>Once you have a ColdBox application imported, you can manually execute 
	events within the ColdBox application. The AppManager (coldbox/appmanager.cfc) 
	includes three methods to help you integrate with your ColdBox applications.</p>
	
	<table class="doc" cellpadding="2" cellspacing="0">
		<thead>
			<tr><td>Metdod</td><td>Return Type</td><td>Description</td></tr>
		</thead>
		<tbody>
			<tr><td>getController(AppName)</td><td>Object</td><td>Returns the ColdBox controller object for a specified imported application</td></tr>
			<tr><td>getRequestCollection(AppName)</td><td>Struct</td><td>Returns the request collection structure for the specified imported application</td></tr>
			<tr><td>runEvent(AppName,Event,Parameters)</td><td>Struct</td><td>Executes a specified event within an imported application</td></tr>
		</tbody>
	</table>
	
	<p>The RunEvent method should nicely handle most of your integration needs. 
	With this method you can provide parameters for an event, execute that event 
	and when the method is finished executing it returns the request collection 
	from the event, so you can get any return data you need back out of the event. 
	It is important to note here that the RunEvent method does not display content 
	or layout, which makes it particularly convenient for integrating with the 
	rest of your application.</p> 
	
	<p>Example:</p>
	<pre class="codeblock">&lt;cfscript&gt; 
	// get the AppManager 
	ioc = getTap().getIoC().getContainer("coldbox"); 
	
	// run the event 
	param = { username = attributes.username, password = attributes.password }; 
	result = ioc.runEvent("Forum","admin.CreateUser",param); 
	
	// get some data back from the event 
	userid = result.newUserID; // now you can do something else with this value 
&lt;/cfscript&gt;</pre>
	
	<p>Of course if you have more complex needs, you can get access to the controller 
	and the request collection with the other two methods.</p>
	
	</cfsavecontent>
</cfoutput>
