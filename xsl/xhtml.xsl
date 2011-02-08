<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xml:base=".">
  <xsl:import href="docbook-xsl/xhtml/chunk.xsl" />

  <xsl:param name="chunk.section.depth" select="0" />
  <xsl:param name="section.autolabel" select="1" />
  <xsl:param name="section.label.includes.component.label" select="1" />

  <!-- Disable the annoying title="" attribute in sections -->
  <xsl:template name="generate.html.title">
  </xsl:template>

  <!-- Custom XHTML head -->
  <xsl:template name="user.head.content">
    <link rel="stylesheet" type="text/css" href="manual.css" />
  </xsl:template>
</xsl:stylesheet>
