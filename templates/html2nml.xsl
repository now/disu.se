<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:func="http://exslt.org/functions"
    xmlns:str="http://exslt.org/string"
    xmlns:string="http://bitwi.se/string"
    exclude-result-prefixes="string"
    extension-element-prefixes="exsl func str">
  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="path"/>

  <xsl:template name="die">
    <xsl:param name="message"/>

    <xsl:message terminate="yes">
      <xsl:text>input/html.xsl: </xsl:text>
      <xsl:value-of select="concat($path, ': ', $message)"/>
    </xsl:message>
  </xsl:template>

  <xsl:template name="die-unknown">
    <xsl:param name="type" select="'element'"/>
    <xsl:param name="prefix" select="''"/>

    <xsl:call-template name="die">
      <xsl:with-param name="message">
        <xsl:text>unmatched </xsl:text>
        <xsl:value-of select="$type"/>
        <xsl:text>: /</xsl:text>
        <xsl:for-each select="ancestor::*">
          <xsl:value-of select="name()"/>
          <xsl:text>/</xsl:text>
        </xsl:for-each>
        <xsl:value-of select="concat($prefix, name())"/>
        <xsl:text>: the input format has changed; add a new rule</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <func:function name="string:ends-with">
    <xsl:param name="string"/>
    <xsl:param name="suffix"/>

    <func:result
        select="substring($string,
                          string-length($string) - string-length($suffix) + 1) =
                  $suffix"/>
  </func:function>

  <func:function name="string:replace-suffix">
    <xsl:param name="string"/>
    <xsl:param name="suffix"/>
    <xsl:param name="replacement"/>

    <xsl:choose>
      <xsl:when test="string:ends-with($string, $suffix)">
        <func:result
            select="concat(substring($string,
                                     1,
                                     string-length($string) -
                                       string-length($suffix)),
                           $replacement)"/>
      </xsl:when>

      <xsl:otherwise>
        <func:result select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <func:function name="string:remove-suffix">
    <xsl:param name="string"/>
    <xsl:param name="suffix"/>

    <func:result select="string:replace-suffix($string, $suffix, '')"/>
  </func:function>

  <func:function name="string:fix-relative-paths">
    <xsl:param name="string" select="."/>

    <xsl:choose>
      <xsl:when test="contains($string, '?') or substring($string, 1, 1) = '/'">
        <func:result select="$string"/>
      </xsl:when>

      <xsl:otherwise>
        <xsl:variable name="path" select="substring-before($string, '#')"/>

        <xsl:choose>
          <xsl:when test="$path">
            <func:result select="concat(string:remove-suffix($path, 'index.html'),
                                        '#', substring-after($string, '#'))"/>
          </xsl:when>

          <xsl:otherwise>
            <func:result select="string:remove-suffix($string, 'index.html')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <xsl:template match="*">
    <xsl:call-template name="die-unknown">
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:call-template name="die-unknown">
      <xsl:with-param name="type">attribute</xsl:with-param>
      <xsl:with-param name="prefix">@</xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="@lang">
    <xsl:attribute name="xml:{local-name()}">
      <xsl:apply-templates/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="@id">
    <xsl:attribute name="xml:{local-name()}">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="@class|@title">
    <xsl:attribute name="{local-name()}">
      <xsl:apply-templates/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="html">
    <nml>
      <xsl:apply-templates select="body/article/*"/>
    </nml>
  </xsl:template>

  <xsl:template match="section|code|span|p">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="h1">
    <title>
      <xsl:apply-templates select="@*|node()"/>
    </title>
  </xsl:template>

  <xsl:template match="dl">
    <xsl:if test="count(dt|dd) > 0">
      <definitions>
        <xsl:call-template name="definitions"/>
      </definitions>
    </xsl:if>
  </xsl:template>

  <xsl:template name="definitions">
    <xsl:param name="begin" select="1"/>
    <xsl:param name="end" select="$begin"/>
    <xsl:param name="terms" select="true()"/>

    <xsl:choose>
      <xsl:when test="$terms and *[$end][self::dt]">
        <xsl:call-template name="definitions">
          <xsl:with-param name="begin" select="$begin"/>
          <xsl:with-param name="end" select="$end + 1"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="$terms">
        <xsl:call-template name="definitions">
          <xsl:with-param name="begin" select="$begin"/>
          <xsl:with-param name="end" select="$end"/>
          <xsl:with-param name="terms" select="false()"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="*[$end][self::dd]">
        <xsl:call-template name="definitions">
          <xsl:with-param name="begin" select="$begin"/>
          <xsl:with-param name="end" select="$end + 1"/>
          <xsl:with-param name="terms" select="false()"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:if test="*[$begin][self::dd]">
          <xsl:call-template name="die">
            <xsl:with-param name="message">
              <xsl:text>definition without term (</xsl:text>
              <xsl:value-of select="concat($begin, ', ', $end)"/>
              <xsl:text>): </xsl:text>
              <xsl:value-of select="dd[$begin]"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

        <xsl:if test="last() > $end and *[$end][not(self::dt)]">
          <xsl:call-template name="die">
            <xsl:with-param name="message">
              <xsl:text>unknown element in dl: </xsl:text>
              <xsl:value-of select="name(*[$end])"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

        <item>
          <xsl:apply-templates select="*[position() >= $begin and $end > position()]"/>
        </item>

        <xsl:if test="count(*) > $end">
          <xsl:call-template name="definitions">
            <xsl:with-param name="begin" select="$end"/>
            <xsl:with-param name="end" select="$end"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="dt">
    <term>
      <xsl:apply-templates select="@*|node()"/>
    </term>
  </xsl:template>

  <xsl:template match="dd">
    <definition>
      <xsl:apply-templates select="@*|node()"/>
    </definition>
  </xsl:template>

  <xsl:template match="ul">
    <itemization>
      <xsl:apply-templates select="@*|node()"/>
    </itemization>
  </xsl:template>

  <xsl:template match="li[node()[1][self::text() and string-length(normalize-space()) > 0]]">
    <item>
      <xsl:apply-templates select="@*"/>
      <p><xsl:apply-templates select="node()"/></p>
    </item>
  </xsl:template>

  <xsl:template match="li">
    <item>
      <xsl:apply-templates select="@*|node()"/>
    </item>
  </xsl:template>

  <xsl:template match="ol">
    <enumeration>
      <xsl:apply-templates select="@*|node()"/>
    </enumeration>
  </xsl:template>

  <xsl:template match="a">
    <link>
      <xsl:apply-templates select="@*|node()"/>
    </link>
  </xsl:template>

  <xsl:template match="a/@href">
    <xsl:attribute name="uri">
      <xsl:value-of select="string:fix-relative-paths()"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="a/@target"/>

  <xsl:template match="em">
    <emphasis>
      <xsl:apply-templates select="@*|node()"/>
    </emphasis>
  </xsl:template>

  <xsl:template match="sub">
    <subscript>
      <xsl:apply-templates select="@*|node()"/>
    </subscript>
  </xsl:template>

  <xsl:template match="sup">
    <superscript>
      <xsl:apply-templates select="@*|node()"/>
    </superscript>
  </xsl:template>

  <xsl:template match="pre[count(*) = 1 and code]">
    <code>
      <xsl:apply-templates select="@*|code/node()"/>
    </code>
  </xsl:template>

  <xsl:template match="pre[@class='code']">
    <code>
      <xsl:apply-templates select="@*|node()"/>
    </code>
  </xsl:template>

  <xsl:template match="table">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="table[thead and not(tbody)]">
    <xsl:copy>
      <xsl:apply-templates select="@*|thead"/>
      <body>
        <xsl:apply-templates select="following-sibling::thead"/>
      </body>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="table[not(thead) and not(tbody)]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <body>
        <xsl:apply-templates/>
      </body>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="thead">
    <head>
      <xsl:apply-templates select="@*|node()"/>
    </head>
  </xsl:template>

  <xsl:template match="tbody">
    <body>
      <xsl:apply-templates select="@*|node()"/>
    </body>
  </xsl:template>

  <xsl:template match="tr">
    <row>
      <xsl:apply-templates select="@*|node()"/>
    </row>
  </xsl:template>

  <xsl:template match="th|td">
    <cell>
      <xsl:apply-templates select="@*|node()"/>
    </cell>
  </xsl:template>
</xsl:stylesheet>
