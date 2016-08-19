<?xml version="1.0" encoding="ISO-8859-1" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" >
  <xsl:output method="xhtml" indent="yes" />
  <xsl:template match="releasenote">
    <html>
	  <style type="text/css">
/* common.css */
* { 
  font-family:arial; 
  font-size:small; 
}
body {
font-size:12px;
}
#wrapper {
  width:800px;
  }
ul  {
  margin:0;
  padding:0 15px;
}
li,a,p,span,strong,b {
  font-size:12px;
}
ol li {
font-size:14px;
color:#999;
}
ol li a {
font-size:12px;
color:#333;
}
table {
border-collapse:collapse;
width:600px;
  border-spacing:0;

}
table thead td,table th {
  color:#333;
  font-weight:bold;
  background:#b9c9fe;
  border:1px solid #999;

}

table tr {
  border:1px solid #333;
}

table tr.alt td {
        background:#ddd;
}

table td {
  font-size:12px;
  padding:2px;
  border:1px solid #999;
}


table tr.list-line-odd td {
    background: #e8edff;
}
table tr.list-line-even td {
    background: #d0dadf;
}

h1 {
  font-size:16px;
}
h2 a,h2 {
  font-size:15px;
}
h3{
font-size:14px;
}
 h4{
  font-size:13px;
}
 h5 {
font-size:12px;
line-height:14px;
padding:0;
margin:0;
}



.xml-content {
width:600px;
height:350px;
overflow:scroll;
border:1px solid #333;
}
.xml-content ul {
list-style-type:circle;
}
.xml-content ul  li{
display:block;
	  </style>
	  <script type="text/javascript">
		function toggleXMLNode(n) {
			a = n.parentNode.children[2];
			if (a.style.display == 'none'){
				a.style.display = 'inherit';
				n.src = 'https://wft.inside.nsn.com/images/icons/minus_small.gif';
            } else {
                a.style.display = 'none';
				n.src = 'https://wft.inside.nsn.com/images/icons/plus_small.gif';
            }			
		}

	  </script>

    <body>
	 
	<h1><xsl:value-of select="system" /> Releasenote <xsl:value-of select="name" /></h1>
	<ol>
		<li><a href="#content_1">SW versions (labels / baselines)</a></li>
		<li><a href="#content_2">Changes</a></li>
		<li><a href="#content_3">Needed Configuration</a></li>
		<li><a href="#content_4">Features</a></li>
		<li><a href="#content_5">Unsupported Features</a></li>
		<li><a href="#content_6">Corrected Faults</a></li>
		<li><a href="#content_7">Restrictions</a></li>
		<li><a href="#content_8">Workarounds</a></li>
		<li><a href="#content_9">Download</a></li>
		<xsl:for-each select="additional/element">
			<xsl:variable name="nr" select="position()+9" />
			<li><a href="#content_{$nr}"><xsl:value-of select="@title" /></a></li>
		</xsl:for-each>
		<xsl:if test="ReleaseInfo">
			<xsl:variable name="nr" select="10+count(additional/element)" />
			<li><a href="#content_{$nr}"><xsl:value-of select="system" /> additional release information</a></li>
		</xsl:if>
		<xsl:if test="testResults">
			<xsl:variable name="nr" select="10+count(additional/element)+count(ReleaseInfo)" />
			<li><a href="#content_{$nr}"><xsl:value-of select="system" /> test results</a></li>
		</xsl:if>
	</ol>
	<h2>Details</h2>
	<ul>
		<li>Release Date: <xsl:value-of select="releaseDate" /> - <xsl:value-of select="releaseTime" /></li>
		<li>Based On: <xsl:value-of select="basedOn" /></li>
		<li>Baseline for <xsl:value-of select="baselineFor/@branch" /></li>
		<li>SVN revision <xsl:value-of select="repositoryRevision" /></li>
	</ul>
	<h2>1. SW Versions (baselines/labels)</h2>
	<a name="content_1" />
	<table border="1">
		<tr>
			<th>Component</th>
			<th>Baseline</th>
		</tr>
		<xsl:for-each select="baselines/baseline">
			<tr  style="color:#00c;">
		      <xsl:choose>
			  <xsl:when test="@changed = 'true'">
			  <td style="color:#00c;"><xsl:value-of select="@name" /></td>
			  <td style="color:#00c;"><xsl:value-of select="." /></td>
			  </xsl:when>
			  <xsl:otherwise>
			  <td><xsl:value-of select="@name" /></td>
			  <td><xsl:value-of select="." /></td>
			  </xsl:otherwise>
			  </xsl:choose>
			</tr>
		</xsl:for-each>
	</table>

	<h2>2. Changes</h2>
	<a name="content_2" />
	<xsl:if test="changes/module">
		<table>
		<tr>
		<th>Module</th>
		<th>Baseline</th>
		<th>Change</th>
		<th>Description</th>
		</tr>

		<xsl:for-each select="changes/module">
			<xsl:for-each select="change">
				<tr>
				  <td><xsl:value-of select="../@name" /></td>
				  <xsl:choose>
				  <xsl:when test="@baseline">
					<td><xsl:value-of select="@baseline" /></td>
				  </xsl:when>
				  <xsl:otherwise>
					<td><xsl:value-of select="/releasenote/name/." /></td>
				  </xsl:otherwise>
				  </xsl:choose>
				  <td><xsl:value-of select="@id" /></td>
				  <td><xsl:value-of select="." /></td>
				</tr>
			</xsl:for-each>
		</xsl:for-each>
		</table>
	</xsl:if>


	<h2>3. Needed Configuration</h2>
	<a name="content_3" />
	<xsl:value-of select="neededConfiguration" />

	<xsl:if test="neededConfigurations/file">
		<table>
		<tr>
		<th>Type</th>
		<th>File</th>
		<th>State</th>
		</tr>

		<xsl:for-each select="neededConfigurations/file">
			<tr>
			  <td><xsl:value-of select="@type" /></td>
			  <td><xsl:value-of select="@name" /></td>
                          <td>
			  <xsl:choose>
			  <xsl:when test="@state = 'changed'">
				<b><xsl:value-of select="@state" /></b>
			  </xsl:when>
			  <xsl:otherwise>
				<xsl:value-of select="@state" />
			  </xsl:otherwise>
			  </xsl:choose>
                          </td>
			</tr>
		</xsl:for-each>
		</table>
	</xsl:if>

	<h2>4. Features</h2>
	<a name="content_4" />
	<xsl:if test="features/feature">
		<table>
		<xsl:for-each select="features/feature">
			<tr>
                          <td><b><xsl:value-of select="@name" /></b></td>
			  <td>
			    <xsl:value-of select="@description" />
			    <xsl:if test="restriction">
			        <div style="color:red;">Restriction: <xsl:value-of select="restriction" /></div>
			    </xsl:if>
			  </td>
			</tr>
		</xsl:for-each>
		</table>
	</xsl:if>

	<h2>5. Unsupported Features</h2>
	<a name="content_5" />
	<xsl:if test="unsupportedFeatures/feature">
		<ul>
		<xsl:for-each select="unsupportedFeatures/feature">
			<tr>
                          <td><b><xsl:value-of select="@name" /></b></td>
			  <td>
			    <xsl:value-of select="@description" />
			    <xsl:if test="restriction">
			        <div style="color:red;">Restriction: <xsl:value-of select="restriction" /></div>
			    </xsl:if>
			  </td>
			</tr>
		</xsl:for-each>
		</ul>
	</xsl:if>
	
	<h2>6. Corrected Faults</h2>
	<a name="content_6" />
	<table border="1">
		<tr>
			<th>Module</th>
			<th>Baseline</th>
			<th>Fault</th>
			<th>Title</th>
		</tr>
		<xsl:for-each select="correctedFaults/module">
			<xsl:for-each select="fault">
				<tr>
				  <td><xsl:value-of select="../@name" /></td>
				  <xsl:choose>
				  <xsl:when test="@baseline">
					<td><xsl:value-of select="@baseline" /></td>
				  </xsl:when>
				  <xsl:otherwise>
					<td><xsl:value-of select="/releasenote/name/." /></td>
				  </xsl:otherwise>
				  </xsl:choose>
				  <td><xsl:value-of select="@id" /></td>
				  <td><xsl:value-of select="." /></td>
				</tr>
			</xsl:for-each>
		</xsl:for-each>
	</table>
	<h2>7. Restrictions</h2>
	<a name="content_7" />
	<xsl:if test="restrictions/module">
		<table>
		<tr>
		<th>Module</th>
		<th>Restriction</th>
		</tr>
		<xsl:for-each select="restrictions/module">
			<xsl:for-each select="restriction">
				<tr>
				  <td><xsl:value-of select="../@name" /></td>
				  <td><xsl:value-of select="." /></td>
				</tr>
			</xsl:for-each>
		</xsl:for-each>
		</table>
	</xsl:if>

	<h2>8. Workarounds</h2>
	<a name="content_8" />
	<xsl:if test="workarounds/workaround">
		<table>
		<tr>
		<th>Module</th>
		<th>Workaround</th>
		</tr>
		<xsl:for-each select="workarounds/workaround">
		<tr>
			<td><xsl:value-of select="@module" /></td>
			<td>
			<xsl:choose>
			<xsl:when test="item">
				<ul>
				<xsl:for-each select="item">
					<li><xsl:value-of select="." /></li>
				</xsl:for-each>
				</ul>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="." />
			</xsl:otherwise>
			</xsl:choose>
			</td>
		</tr>
		</xsl:for-each>
		</table>
	</xsl:if>

	<h2>9. Download</h2>
	<a name="content_9" />
	<xsl:for-each select="download/downloadItem">
		<h4><xsl:value-of select="description" /></h4>
		<p><xsl:value-of select="name" /></p>
	</xsl:for-each>
	
	<xsl:for-each select="additional/element">
		<xsl:variable name="nr" select="position()+9" />
		<h2><xsl:value-of select="$nr" />. <xsl:value-of select="@title" /></h2>
		<a name="content_{$nr}" />
		<xsl:choose>
		<xsl:when test="@type='html'">
			<xsl:copy-of select="."/>
		</xsl:when>
		<xsl:when test="@type='xml'">
			<div class="xml-content">
				<ul>
				<xsl:for-each select="./*">
					
						<xsl:call-template name="xml-tree">
							<xsl:with-param name="element">
								<xsl:value-of select="." />
							</xsl:with-param>
						</xsl:call-template>
				</xsl:for-each>
				</ul>
			</div>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="PreserveLineBreaks">
				<xsl:with-param name="text" select="."/>
			</xsl:call-template>

		</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
	<xsl:if test="ReleaseInfo">
		<xsl:variable name="nr" select="10+count(additional/element)" />
		<h2><xsl:value-of select="$nr" />. <xsl:value-of select="system" /> additional release information</h2>
		<a name="content_{$nr}" />
		<xsl:if test="ReleaseInfo/delivered">
		  <h3>Delivered</h3>
		  <xsl:for-each-group select="ReleaseInfo/delivered" group-by="@tag">
		    <b><u><xsl:value-of select="concat(current-grouping-key(), ':')"/></u></b>

		    <ul>
		      <xsl:for-each select="current-group()">
			<xsl:sort select="@date"/>
			<li>
			  <xsl:value-of select="@module"/> <u><xsl:value-of select="@person"/></u> on <xsl:value-of select="@date"/>: <xsl:value-of select="."/> 
			</li>
		      </xsl:for-each>
		    </ul>
		  </xsl:for-each-group>
		</xsl:if>
		<xsl:if test="ReleaseInfo/changed">
		  <h3>Changed</h3>
		  <xsl:for-each-group select="ReleaseInfo/changed" group-by="@tag">
		    <b><u><xsl:value-of select="concat(current-grouping-key(), ':')"/></u></b>

		    <ul>
		      <xsl:for-each select="current-group()">
			<xsl:sort select="@date"/>
			<li>
			  <xsl:value-of select="@module"/> <u><xsl:value-of select="@person"/></u> on <xsl:value-of select="@date"/>: 
			    <xsl:call-template name="PreserveLineBreaks">
				<xsl:with-param name="text" select="."/>
			    </xsl:call-template>
			</li>
		      </xsl:for-each>
		    </ul>
		  </xsl:for-each-group>
		</xsl:if>
	</xsl:if>
	<xsl:if test="testResults">
		<xsl:variable name="nr" select="10+count(additional/element)+count(ReleaseInfo)" />
		<h2><xsl:value-of select="$nr" />. <xsl:value-of select="system" /> test results</h2>
		<a name="content_{$nr}" />
		<ul>
		<xsl:for-each select="testResults/testResult">
		  <xsl:sort select="@name"/>
			<li><a href="{@url}"><xsl:value-of select="@name" /></a></li>
		</xsl:for-each>
		</ul>
	</xsl:if>
    </body>
    </html>
 </xsl:template>   
 
 <xsl:template name="xml-tree">
	<xsl:param name="elem" />
	<xsl:if test="name() != ''">
		<li>
		<xsl:choose>
		<xsl:when test="count(*) > 0">
			<img src="https://wft.inside.nsn.com/images/icons/plus_small.gif" onclick="toggleXMLNode(this);" width="16" height="16" />
			<b><xsl:value-of select="name()" /></b>
		</xsl:when>
		<xsl:otherwise>
			<img src="https://wft.inside.nsn.com/images/icons/bullet_green.gif"/>
			<b><xsl:value-of select="name()" /></b>=
		</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="count(@*) > 0">
		(
		<xsl:for-each select="@*">
		<xsl:value-of select="name()" />=<xsl:value-of select="." />
		</xsl:for-each>
		)
		</xsl:if>		
		<xsl:choose>
		<xsl:when test="count(*) > 0">
			<ul style="display:none;">
			<xsl:for-each select="child::node()">
				<xsl:call-template name="xml-tree">
					<xsl:with-param name="elem">
						<xsl:value-of select="." />
					</xsl:with-param>
				</xsl:call-template>
			</xsl:for-each>
			</ul>
		</xsl:when>
		<xsl:when test=". != ''">
			<xsl:value-of select="." />
		</xsl:when>
		</xsl:choose>

		</li>
	</xsl:if>
 </xsl:template>
<xsl:template name="PreserveLineBreaks">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="contains($text,'&#xA;')">
                <xsl:value-of select="substring-before($text,'&#xA;')"/>
                <br/>
                <xsl:call-template name="PreserveLineBreaks">
                    <xsl:with-param name="text">
                        <xsl:value-of select="substring-after($text,'&#xA;')"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


 </xsl:stylesheet>

